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
        case .invalidURL:           return "Invalid URL"
        case .invalidResponse:      return "Invalid server response"
        case .decodingError(let e): return "Data parsing error: \(e.localizedDescription)"
        case .serverError(let c):   return "Server error (\(c))"
        case .noInternet:           return "No internet connection"
        case .unknown(let e):       return e.localizedDescription
        }
    }
}

actor NetworkService {
    static let shared = NetworkService()

    private let openFoodFactsBaseURL = "https://world.openfoodfacts.org"

    // FIX: 503 retry logic matching Android NetworkClient (up to 10 retries, exponential back-off)
    private let maxRetries = 10

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 60
        config.timeoutIntervalForResource = 180
        return URLSession(configuration: config)
    }()

    private let decoder = JSONDecoder()

    // MARK: - Open Food Facts with 503 retry
    func searchProducts(query: String, pageSize: Int = 50) async throws -> [APIProduct] {
        var components = URLComponents(string: "\(openFoodFactsBaseURL)/cgi/search.pl")!
        components.queryItems = [
            .init(name: "action",       value: "process"),
            .init(name: "json",         value: "true"),
            .init(name: "search_terms", value: query),
            .init(name: "page_size",    value: "\(pageSize)"),
            .init(name: "fields",       value: "product_name,brands,image_url,nutriscore_grade,nutriments,ingredients_text,ingredients_text_en")
        ]
        let response: FoodAPIResponse = try await getWithRetry(url: components.url!)
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
        let response: FoodAPIResponse = try await getWithRetry(url: components.url!)
        return response.products
    }

    func analyzeImageScan(imageData: Data, healthInfo: String) async throws -> AnalysisResponse {
        try await AINetworkService.shared.analyzeImageScan(imageData: imageData, healthInfo: healthInfo)
    }
    func analyzeIngredients(ingredients: String, healthInfo: String) async throws -> AnalysisResponse {
        try await AINetworkService.shared.analyzeIngredients(ingredients: ingredients, healthInfo: healthInfo)
    }

    private func getWithRetry<T: Decodable>(url: URL) async throws -> T {
        var retryCount = 0
        while true {
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, http.statusCode == 503, retryCount < maxRetries {
                retryCount += 1
                let delay = min(UInt64(retryCount) * 500_000_000, 3_000_000_000) // 0.5s * retry, max 3s
                try await Task.sleep(nanoseconds: delay)
                continue
            }
            try validateResponse(response)
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }
        }
    }

    private func get<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        do { return try decoder.decode(T.self, from: data) }
        catch { throw NetworkError.decodingError(error) }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw NetworkError.serverError(http.statusCode) }
    }
}
