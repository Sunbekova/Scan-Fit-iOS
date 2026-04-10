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
        cfg.timeoutIntervalForRequest = 60
        cfg.timeoutIntervalForResource = 180
        return URLSession(configuration: cfg)
    }()
    private let decoder = JSONDecoder()

    // MARK: - Health + AI

    private var healthInfo: String {
        if let vm = profileVM, !vm.healthInfoForAI.isEmpty, vm.healthInfoForAI != "None" {
            return vm.healthInfoForAI
        }
        // Backward compatibility for users who haven't updated their profile to the cloud yet
        let legacy = UserDefaults.standard.stringArray(forKey: "user_diseases") ?? []
        return legacy.isEmpty ? "None" : legacy.joined(separator: ", ")
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
        do {
            let response = try await AINetworkService.shared.analyzeIngredients(
                ingredients: text,
                healthInfo: healthInfo)
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
        let targetSize = CGSize(width: image.size.width * scale,
                                height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: targetSize)) }
        return resized.jpegData(compressionQuality: 0.6)
    }
}
