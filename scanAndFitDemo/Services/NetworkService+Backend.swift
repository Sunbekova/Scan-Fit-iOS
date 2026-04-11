import Foundation

struct AppConfig {
    static let backendBaseURL = "http://46.101.137.109:3000"

    static var aiServiceBaseURL: String {
        if let saved = UserDefaults.standard.string(forKey: "ai_service_url"), !saved.isEmpty {
            return saved
        }
        return "http://46.101.137.109:8001"
    }
}

// MARK: - NetworkService Extension (SAFE — no breaking changes)

extension NetworkService {
    static var aiBaseURLDynamic: String { AppConfig.aiServiceBaseURL }
    static var backendBaseURLDynamic: String { AppConfig.backendBaseURL }
}


actor AINetworkService {
    static let shared = AINetworkService()

    private var aiBaseURL: String { AppConfig.aiServiceBaseURL }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 240
        return URLSession(configuration: config)
    }()

    private let decoder = JSONDecoder()

    func analyzeImageScan(imageData: Data, healthInfo: String) async throws -> AnalysisResponse {
        guard let url = URL(string: "\(aiBaseURL)/analyze-scan") else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.appendMultipart(boundary: boundary, name: "file", filename: "scan.jpg", mimeType: "image/jpeg", data: imageData)
        body.appendMultipartText(boundary: boundary, name: "health_info", value: healthInfo)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(AnalysisResponse.self, from: data)
    }

    func analyzeIngredientsFull(
        ingredients: String,
        healthInfo: String,
        productJson: String? = nil,
        userProfileJson: String? = nil
    ) async throws -> AnalysisResponse {
        guard let url = URL(string: "\(aiBaseURL)/ingredient") else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "ingredients": ingredients,
            "health_info": healthInfo
        ]
        if let pj = productJson {
            body["product_json"] = pj
            if let data = pj.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: data) {
                body["product"] = parsed
            }
        }
        if let uj = userProfileJson {
            body["user_profile_json"] = uj
            if let data = uj.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: data) {
                body["user"] = parsed
            }
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(AnalysisResponse.self, from: data)
    }

    func analyzeIngredients(ingredients: String, healthInfo: String) async throws -> AnalysisResponse {
        return try await analyzeIngredientsFull(ingredients: ingredients, healthInfo: healthInfo)
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw NetworkError.serverError(http.statusCode) }
    }
}
