import Foundation

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case serverError(Int)
    case noInternet
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .decodingError(let e): return "Data parsing error: \(e.localizedDescription)"
        case .serverError(let code): return "Server error (\(code))"
        case .noInternet: return "No internet connection"
        case .unknown(let e): return e.localizedDescription
        }
    }
}

// MARK: - Network Service

actor NetworkService {
    static let shared = NetworkService()

    private let openFoodFactsBaseURL = "https://world.openfoodfacts.org"
    private let aiBaseURL = "http://172.20.10.9"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 180
        return URLSession(configuration: config)
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    // MARK: - Open Food Facts

    func searchProducts(query: String, pageSize: Int = 50) async throws -> [APIProduct] {
        var components = URLComponents(string: "\(openFoodFactsBaseURL)/cgi/search.pl")!
        components.queryItems = [
            .init(name: "action", value: "process"),
            .init(name: "json", value: "true"),
            .init(name: "search_terms", value: query),
            .init(name: "page_size", value: "\(pageSize)"),
            .init(name: "fields", value: "product_name,brands,image_url,nutriscore_grade,nutriments,ingredients_text,ingredients_text_en")
        ]

        let response: FoodAPIResponse = try await get(url: components.url!)
        return response.products
    }

    func getProductsByCategory(category: String, pageSize: Int = 20) async throws -> [APIProduct] {
        var components = URLComponents(string: "\(openFoodFactsBaseURL)/cgi/search.pl")!
        components.queryItems = [
            .init(name: "action", value: "process"),
            .init(name: "json", value: "true"),
            .init(name: "tagtype_0", value: "categories"),
            .init(name: "tag_contains_0", value: "contains"),
            .init(name: "tag_0", value: category),
            .init(name: "page_size", value: "\(pageSize)"),
            .init(name: "fields", value: "product_name,brands,image_url,nutriscore_grade,nutriments,ingredients_text,ingredients_text_en")
        ]

        let response: FoodAPIResponse = try await get(url: components.url!)
        return response.products
    }

    // MARK: - AI Analysis

    func analyzeImageScan(imageData: Data, healthInfo: String) async throws -> AnalysisResponse {
        let url = URL(string: "\(aiBaseURL)/analyze-scan")!
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
        let url = URL(string: "\(aiBaseURL)/ingredient")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["ingredients": ingredients, "health_info": healthInfo]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(AnalysisResponse.self, from: data)
    }

    // MARK: - Generic GET

    private func get<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
    }
}

// MARK: - Data Extension for Multipart

extension Data {
    mutating func appendMultipart(boundary: String, name: String, filename: String, mimeType: String, data: Data) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }

    mutating func appendMultipartText(boundary: String, name: String, value: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append(value.data(using: .utf8)!)
        append("\r\n".data(using: .utf8)!)
    }
}
