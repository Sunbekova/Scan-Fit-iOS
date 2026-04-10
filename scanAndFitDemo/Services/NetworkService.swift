import Foundation

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


actor NetworkService {
    static let shared = NetworkService()

    private let openFoodFactsBaseURL = "https://world.openfoodfacts.org"
    private var aiBaseURL: String { AppConfig.aiServiceBaseURL }
    //private let aiBaseURL = "http://192.168.0.105" //вайфай

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 180
        return URLSession(configuration: config)
    }()

    private let decoder = JSONDecoder()
    
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

    // MARK: - ии

    func analyzeImageScan(imageData: Data, healthInfo: String) async throws -> AnalysisResponse {
        try await AINetworkService.shared.analyzeImageScan(
            imageData: imageData,
            healthInfo: healthInfo
        )
    }

    func analyzeIngredients(ingredients: String, healthInfo: String) async throws -> AnalysisResponse {
        try await AINetworkService.shared.analyzeIngredients(
            ingredients: ingredients,
            healthInfo: healthInfo
        )
    }
    
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

private func addAuthHeader(_ request: inout URLRequest) throws {
    guard let bearer = TokenManager.shared.bearerToken else {
        throw NetworkError.invalidResponse
    }
    request.setValue(bearer, forHTTPHeaderField: "Authorization")
}

