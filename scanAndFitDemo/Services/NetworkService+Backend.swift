import Foundation


struct AppConfig {
    static let backendBaseURL = "http://46.101.137.109:3000"

    static var aiServiceBaseURL: String {
        if let saved = UserDefaults.standard.string(forKey: "ai_service_url"),
           !saved.isEmpty {
            return saved
        }
        return "http://46.101.137.109:8080"
    }
}

// MARK: - NetworkService Extension (SAFE — no breaking changes)

extension NetworkService {
    static var aiBaseURLDynamic: String {
        AppConfig.aiServiceBaseURL
    }

    static var backendBaseURLDynamic: String {
        AppConfig.backendBaseURL
    }
}


actor AINetworkService {
    static let shared = AINetworkService()

    private var aiBaseURL: String { AppConfig.aiServiceBaseURL }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 180
        return URLSession(configuration: config)
    }()

    private let decoder = JSONDecoder()


    func analyzeImageScan(imageData: Data, healthInfo: String) async throws -> AnalysisResponse {
        guard let url = URL(string: "\(aiBaseURL)/analyze-scan") else {
            throw NetworkError.invalidURL
        }
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


    func analyzeIngredients(ingredients: String, healthInfo: String) async throws -> AnalysisResponse {
        guard let url = URL(string: "\(aiBaseURL)/ingredient")else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "ingredients": ingredients,
            "health_info": healthInfo
        ]

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        return try decoder.decode(AnalysisResponse.self, from: data)
    }


    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.serverError(http.statusCode)
        }
    }
}
