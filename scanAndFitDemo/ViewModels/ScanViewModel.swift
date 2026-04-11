import Foundation
import UIKit
import Combine

enum ScanState {
    case idle
    case analyzing
    case result(AnalysisResponse)
    case error(String)
}

@MainActor
final class ScanViewModel: ObservableObject {
    @Published var scanState: ScanState = .idle
    @Published var capturedImage: UIImage?

    var profileVM: UserProfileViewModel?

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 120
        cfg.timeoutIntervalForResource = 240
        return URLSession(configuration: cfg)
    }()

    // MARK: - Health + AI

    private var healthInfo: String {
        if let vm = profileVM, !vm.healthInfoForAI.isEmpty, vm.healthInfoForAI != "None reported" {
            return vm.healthInfoForAI
        }
        let legacy = UserDefaults.standard.stringArray(forKey: "user_diseases") ?? []
        return legacy.isEmpty ? "None" : legacy.joined(separator: ", ")
    }

    private func fetchUserProfileJson() async -> String? {
        do {
            let resp = try await BackendUserService.shared.getUserDetails()
            if let data = resp.data {
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                if let jsonData = try? encoder.encode(data),
                   let str = String(data: jsonData, encoding: .utf8) {
                    return str
                }
            }
        } catch {}
        return nil
    }

    // MARK: - Analyze img

    func analyzePhoto(_ image: UIImage) async {
        scanState = .analyzing
        capturedImage = image

        guard let data = compressImage(image) else {
            scanState = .error("Failed to process image")
            return
        }

        do {
            let response = try await AINetworkService.shared.analyzeImageScan(
                imageData: data,
                healthInfo: healthInfo
            )
            scanState = .result(response)
        } catch {
            scanState = .error(error.localizedDescription)
        }
    }

    // MARK: - ingredients

    func analyzeIngredients(_ text: String) async {
        scanState = .analyzing
        let userProfileJson = await fetchUserProfileJson()
        do {
            let response = try await AINetworkService.shared.analyzeIngredientsFull(
                ingredients: text,
                healthInfo: userProfileJson != nil ? "User health profile JSON:\n\(userProfileJson!)" : healthInfo,
                productJson: nil,
                userProfileJson: userProfileJson
            )
            scanState = .result(response)
        } catch {
            scanState = .error(error.localizedDescription)
        }
    }

    func reset() {
        scanState = .idle
        capturedImage = nil
    }

    private func compressImage(_ image: UIImage) -> Data? {
        let maxDimension: CGFloat = 1024
        let scale = min(1.0, maxDimension / max(image.size.width, image.size.height))
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: targetSize)) }
        return resized.jpegData(compressionQuality: 0.6)
    }
}
