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

    private let network = NetworkService.shared
    private let userDefaults = UserDefaults.standard

    var healthInfo: String {
        let diseases = userDefaults.stringArray(forKey: "user_diseases") ?? []
        return diseases.isEmpty ? "None" : diseases.joined(separator: ", ")
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
            let response = try await network.analyzeImageScan(imageData: data, healthInfo: healthInfo)
            scanState = .result(response)
        } catch {
            scanState = .error(error.localizedDescription)
        }
    }

    // MARK: - ingredients

    func analyzeIngredients(_ text: String) async {
        scanState = .analyzing
        do {
            let response = try await network.analyzeIngredients(ingredients: text, healthInfo: "General Analysis")
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
        let scale = maxDimension / max(image.size.width, image.size.height)
        let targetSize = scale < 1
            ? CGSize(width: image.size.width * scale, height: image.size.height * scale)
            : image.size

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: targetSize)) }
        return resized.jpegData(compressionQuality: 0.6)
    }
}
