import Foundation
import UIKit
import Combine

enum ScanState {
    case idle
    case analyzing
    case result(AnalysisResponse)
    case error(String)
    case limitExceeded(String)
}

@MainActor
final class ScanViewModel: ObservableObject {
    @Published var scanState: ScanState = .idle
    @Published var capturedImage: UIImage?
    @Published var scanLimitData: BackendProductScanLimitData?

    var profileVM: UserProfileViewModel?

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 120
        cfg.timeoutIntervalForResource = 240
        return URLSession(configuration: cfg)
    }()
//health
    private var healthInfoFallback: String {
        if let vm = profileVM, !vm.healthInfoForAI.isEmpty, vm.healthInfoForAI != "None reported" {
            return vm.healthInfoForAI
        }
        let legacy = UserDefaults.standard.stringArray(forKey: "user_diseases") ?? []
        return legacy.isEmpty ? "None" : legacy.joined(separator: ", ")
    }

    private func fetchUserContext() async -> (detailsJson: String?, caloriesJson: String?, waterJson: String?) {
        async let detailsTask: BackendUserDetailsResponse? = try? BackendUserService.shared.getUserDetails()
        async let caloriesTask: BackendUserCaloriesResponse? = try? BackendUserService.shared.getTodayCalories()
        async let waterTask: BackendUserWaterResponse? = try? BackendUserService.shared.getTodayWater()
        let (details, calories, water) = await (detailsTask, caloriesTask, waterTask)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let detailsJson: String? = details?.data.flatMap {
            guard let d = try? encoder.encode($0) else { return nil }
            return String(data: d, encoding: .utf8)
        }
        let caloriesJson: String? = calories?.data.flatMap {
            guard let d = try? encoder.encode($0) else { return nil }
            return String(data: d, encoding: .utf8)
        }
        let waterJson: String? = water?.data.flatMap {
            guard let d = try? encoder.encode($0) else { return nil }
            return String(data: d, encoding: .utf8)
        }
        return (detailsJson, caloriesJson, waterJson)
    }

    private func buildUserInformationJson(details: String?, calories: String?, water: String?) -> String? {
        var obj: [String: Any] = [:]
        if let d = details, let parsed = try? JSONSerialization.jsonObject(with: Data(d.utf8)) { obj["user"] = parsed }
        if let c = calories, let parsed = try? JSONSerialization.jsonObject(with: Data(c.utf8)) { obj["user_calories_today"] = parsed }
        if let w = water, let parsed = try? JSONSerialization.jsonObject(with: Data(w.utf8)) { obj["user_water_today"] = parsed }
        guard let data = try? JSONSerialization.data(withJSONObject: obj),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
//scanlimit check
    private func checkScanLimit() async -> Bool {
        do {
            let resp = try await BackendUserService.shared.getProductScanLimit()
            scanLimitData = resp.data
            let isUnlimited = resp.data?.isUnlimited ?? false
            let isExceeded = resp.data?.isExceeded ?? false
            let remaining = resp.data?.remaining ?? 0
            if isUnlimited { return true }
            if isExceeded || remaining <= 0 {
                let msg = resp.message ?? "Daily scan limit reached. Upgrade to Pro for unlimited scans."
                scanState = .limitExceeded(msg)
                return false
            }
            return true
        } catch {
            return true
        }
    }

    private func decreaseScanLimit() async {
        _ = try? await BackendUserService.shared.decreaseProductScanLimit()
        scanLimitData = (try? await BackendUserService.shared.getProductScanLimit())?.data
    }
//analiz img
    func analyzePhoto(_ image: UIImage) async {
        scanState = .analyzing
        capturedImage = image
        guard let data = compressImage(image) else { scanState = .error("Failed to process image"); return }
        let allowed = await checkScanLimit()
        guard allowed else { return }
        let context = await fetchUserContext()
        let userInfoJson = buildUserInformationJson(details: context.detailsJson, calories: context.caloriesJson, water: context.waterJson)
        let healthInfo = userInfoJson != nil ? "User health profile JSON:\n\(userInfoJson!)" : healthInfoFallback
        do {
            let response = try await AINetworkService.shared.analyzeImageScanWithUserContext(
                imageData: data, healthInfo: healthInfo, userInformationJson: userInfoJson)
            await decreaseScanLimit()
            scanState = .result(response)
        } catch {
            scanState = .error(error.localizedDescription)
        }
    }
//analiz ingred
    func analyzeIngredients(_ text: String) async {
        scanState = .analyzing
        let allowed = await checkScanLimit()
        guard allowed else { return }
        let context = await fetchUserContext()
        let userInfoJson = buildUserInformationJson(details: context.detailsJson, calories: context.caloriesJson, water: context.waterJson)
        let healthInfo = userInfoJson != nil ? "User health profile JSON:\n\(userInfoJson!)" : healthInfoFallback
        do {
            let response = try await AINetworkService.shared.analyzeIngredientsFull(
                ingredients: text, healthInfo: healthInfo, productJson: nil, userProfileJson: userInfoJson)
            await decreaseScanLimit()
            scanState = .result(response)
        } catch {
            scanState = .error(error.localizedDescription)
        }
    }

    func loadScanLimit() async {
        scanLimitData = (try? await BackendUserService.shared.getProductScanLimit())?.data
    }

    func reset() { scanState = .idle; capturedImage = nil }

    private func compressImage(_ image: UIImage) -> Data? {
        let maxDimension: CGFloat = 1024
        let scale = min(1.0, maxDimension / max(image.size.width, image.size.height))
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: targetSize)) }
        return resized.jpegData(compressionQuality: 0.6)
    }
}
