import Foundation

// /api/v1/user/* endpoints

actor BackendUserService {
    static let shared = BackendUserService()

    private let baseURL = "http://46.101.137.109:3000"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 180
        return URLSession(configuration: config)
    }()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// GET /api/v1/user/me
    func getMe() async throws -> BackendUserAccountResponse {
        return try await get(path: "/api/v1/user/me")
    }

    func getUserRole() async throws -> BackendUserRoleResponse {
        return try await get(path: "/api/v1/user/me/role")
    }

    func getUserDetails() async throws -> BackendUserDetailsResponse {
        return try await get(path: "/api/v1/user/me/details")
    }

    func createMeasure(_ req: BackendUserMeasureRequest) async throws -> BackendUserMeasureResponse {
        return try await post(path: "/api/v1/user/measure/create", body: req)
    }

    func getMeasure() async throws -> BackendUserMeasureResponse {
        return try await get(path: "/api/v1/user/measure/get")
    }

    func updateMeasure(_ req: BackendUpdateUserMeasureRequest) async throws -> BackendUserMeasureResponse {
        return try await put(path: "/api/v1/user/measure/update", body: req)
    }


    func getDietTypes() async throws -> BackendDietTypeListResponse {
        return try await get(path: "/api/v1/user/diet-type/list")
    }

    func updateDietType(id: Int, isActive: Bool) async throws -> BackendUpdateDietTypeResponse {
        return try await put(path: "/api/v1/user/diet-type/update/\(id)", body: BackendUpdateDietTypeRequest(isActive: isActive))
    }

    func getDietaryPreferences() async throws -> BackendDietTypeListResponse {
        return try await get(path: "/api/v1/user/dietary-preference/list")
    }

    func updateDietaryPreference(id: Int, isActive: Bool) async throws -> BackendUpdateDietTypeResponse {
        return try await put(path: "/api/v1/user/dietary-preference/update/\(id)", body: BackendUpdateDietTypeRequest(isActive: isActive))
    }

    func getHealthConditions() async throws -> BackendDietTypeListResponse {
        return try await get(path: "/api/v1/user/health-condition/list")
    }

    func updateHealthCondition(id: Int, isActive: Bool) async throws -> BackendUpdateDietTypeResponse {
        return try await put(path: "/api/v1/user/health-condition/update/\(id)", body: BackendUpdateDietTypeRequest(isActive: isActive))
    }

    /// GET /api/v1/user/disease/list
    func getDiseases() async throws -> BackendDiseaseListResponse {
        return try await get(path: "/api/v1/user/disease/list")
    }

    func updateDisease(id: Int, diseaseLevelId: Int, isActive: Bool) async throws -> BackendUpdateDietTypeResponse {
        return try await put(path: "/api/v1/user/disease/update/\(id)", body: BackendUpdateDiseaseRequest(diseaseLevelId: diseaseLevelId, isActive: isActive))
    }

    func getDiseaseLevels() async throws -> BackendDiseaseLevelListResponse {
        return try await get(path: "/api/v1/user/disease-level/list")
    }


    func getWeightManagement() async throws -> BackendWeightManagementResponse {
        return try await get(path: "/api/v1/user/weight-management/get")
    }

    func updateWeightManagement(_ req: BackendUpdateWeightManagementRequest) async throws -> BackendUpdateDietTypeResponse {
        return try await put(path: "/api/v1/user/weight-management/update", body: req)
    }


    func getTodayCalories() async throws -> BackendUserCaloriesResponse {
        return try await get(path: "/api/v1/user/user-calories/today")
    }

    func getCaloriesByDay(day: String) async throws -> BackendUserCaloriesResponse {
        return try await get(path: "/api/v1/user/user-calories?day=\(day)")
    }

    func updateUserCalories(day: String, req: BackendUpdateUserCaloriesRequest) async throws -> BackendUserCaloriesResponse {
        return try await putWithQuery(path: "/api/v1/user/user-calories/update", query: "day=\(day)", body: req)
    }

    func refreshTodayCalories() async throws -> BackendUserCaloriesResponse {
        return try await put(path: "/api/v1/user/user-calories/today/refresh", body: EmptyBody())
    }

    func getTodayWater() async throws -> BackendUserWaterResponse {
        return try await get(path: "/api/v1/user/user-water/today")
    }

    func getWaterByDay(day: String) async throws -> BackendUserWaterResponse {
        return try await get(path: "/api/v1/user/user-water?day=\(day)")
    }

    func updateWater(day: String, water: Int) async throws -> BackendUserWaterResponse {
        return try await putWithQuery(path: "/api/v1/user/user-water/update", query: "day=\(day)", body: BackendUpdateUserWaterRequest(water: water))
    }

    func createUserDailyEat(_ req: BackendCreateUserDailyEatRequest) async throws -> BackendCreateUserDailyEatResponse {
        return try await post(path: "/api/v1/product/user-daily-eat/create", body: req)
    }

    func createProductScan(_ req: BackendCreateProductScanRequest) async throws -> BackendCreateProductScanResponse {
        return try await post(path: "/api/v1/product/product-scans/create", body: req)
    }

    func updateProductScan(id: Int, _ req: BackendCreateProductScanRequest) async throws -> BackendCreateProductScanResponse {
        return try await put(path: "/api/v1/product/product-scans/update/\(id)", body: req)
    }

    func getProductScanByName(productName: String) async throws -> BackendProductScanResponse {
        let encoded = productName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? productName
        return try await get(path: "/api/v1/product/product-scans/get-by-product-name?product_name=\(encoded)")
    }

    private struct EmptyBody: Codable {}

    private func get<Response: Decodable>(path: String) async throws -> Response {
        let request = try buildRequest(path: path, method: "GET")
        return try await execute(request)
    }

    private func post<Body: Encodable, Response: Decodable>(path: String, body: Body) async throws -> Response {
        var request = try buildRequest(path: path, method: "POST")
        request.httpBody = try encoder.encode(body)
        return try await execute(request)
    }

    private func put<Body: Encodable, Response: Decodable>(path: String, body: Body) async throws -> Response {
        var request = try buildRequest(path: path, method: "PUT")
        request.httpBody = try encoder.encode(body)
        return try await execute(request)
    }

    private func putWithQuery<Body: Encodable, Response: Decodable>(path: String, query: String, body: Body) async throws -> Response {
        var request = try buildRequest(path: "\(path)?\(query)", method: "PUT")
        request.httpBody = try encoder.encode(body)
        return try await execute(request)
    }

    private func buildRequest(path: String, method: String) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let bearer = TokenManager.shared.bearerToken else {
            throw BackendError.notAuthenticated
        }
        request.setValue(bearer, forHTTPHeaderField: "Authorization")
        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        if http.statusCode == 401 {
            await MainActor.run { TokenManager.shared.clearAll() }
            throw BackendError.apiError("Session expired. Please log in again.")
        }
        guard (200..<300).contains(http.statusCode) else {
            if let errResponse = try? decoder.decode(BackendBaseResponse.self, from: data) {
                throw BackendError.apiError(errResponse.message ?? "Error \(http.statusCode)")
            }
            throw NetworkError.serverError(http.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
