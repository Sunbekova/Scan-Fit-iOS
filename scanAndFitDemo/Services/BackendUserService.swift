import Foundation

// /api/v1/user/* endpoints

actor BackendUserService {
    static let shared = BackendUserService()

    private let baseURL = "http://46.101.137.109:3000"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()


    /// GET /api/v1/user/me
    func getMe() async throws -> BackendUserAccountResponse {
        return try await get(path: "/api/v1/user/me")
    }


    /// POST /api/v1/user/measure/create
    func createMeasure(_ req: BackendUserMeasureRequest) async throws -> BackendUserMeasureResponse {
        return try await post(path: "/api/v1/user/measure/create", body: req)
    }

    /// GET /api/v1/user/measure/get
    func getMeasure() async throws -> BackendUserMeasureResponse {
        return try await get(path: "/api/v1/user/measure/get")
    }

    /// PUT /api/v1/user/measure/update
    func updateMeasure(_ req: BackendUpdateUserMeasureRequest) async throws -> BackendUserMeasureResponse {
        return try await put(path: "/api/v1/user/measure/update", body: req)
    }


    /// GET /api/v1/user/diet-type/list
    func getDietTypes() async throws -> BackendDietTypeListResponse {
        return try await get(path: "/api/v1/user/diet-type/list")
    }

    /// PUT /api/v1/user/diet-type/update/:id
    func updateDietType(id: Int, isActive: Bool) async throws -> BackendUpdateDietTypeResponse {
        let req = BackendUpdateDietTypeRequest(isActive: isActive)
        return try await put(path: "/api/v1/user/diet-type/update/\(id)", body: req)
    }

    /// GET /api/v1/user/dietary-preference/list
    func getDietaryPreferences() async throws -> BackendDietTypeListResponse {
        return try await get(path: "/api/v1/user/dietary-preference/list")
    }

    /// PUT /api/v1/user/dietary-preference/update/:id
    func updateDietaryPreference(id: Int, isActive: Bool) async throws -> BackendUpdateDietTypeResponse {
        let req = BackendUpdateDietTypeRequest(isActive: isActive)
        return try await put(path: "/api/v1/user/dietary-preference/update/\(id)", body: req)
    }


    /// GET /api/v1/user/health-condition/list
    func getHealthConditions() async throws -> BackendDietTypeListResponse {
        return try await get(path: "/api/v1/user/health-condition/list")
    }

    /// PUT /api/v1/user/health-condition/update/:id
    func updateHealthCondition(id: Int, isActive: Bool) async throws -> BackendUpdateDietTypeResponse {
        let req = BackendUpdateDietTypeRequest(isActive: isActive)
        return try await put(path: "/api/v1/user/health-condition/update/\(id)", body: req)
    }

    /// GET /api/v1/user/disease/list
    func getDiseases() async throws -> BackendDiseaseListResponse {
        return try await get(path: "/api/v1/user/disease/list")
    }

    /// PUT /api/v1/user/disease/update/:id
    func updateDisease(id: Int, diseaseLevelId: Int, isActive: Bool) async throws -> BackendUpdateDietTypeResponse {
        let req = BackendUpdateDiseaseRequest(diseaseLevelId: diseaseLevelId, isActive: isActive)
        return try await put(path: "/api/v1/user/disease/update/\(id)", body: req)
    }

    /// GET /api/v1/user/disease-level/list
    func getDiseaseLevels() async throws -> BackendDiseaseLevelListResponse {
        return try await get(path: "/api/v1/user/disease-level/list")
    }


    /// GET /api/v1/user/weight-management/get
    func getWeightManagement() async throws -> BackendWeightManagementResponse {
        return try await get(path: "/api/v1/user/weight-management/get")
    }

    /// PUT /api/v1/user/weight-management/update
    func updateWeightManagement(_ req: BackendUpdateWeightManagementRequest) async throws -> BackendUpdateDietTypeResponse {
        return try await put(path: "/api/v1/user/weight-management/update", body: req)
    }


    /// GET /api/v1/user/user-calories/today
    func getTodayCalories() async throws -> BackendUserCaloriesResponse {
        return try await get(path: "/api/v1/user/user-calories/today")
    }

    /// POST /api/v1/user/user-calories/create
    func createCaloriesEntry(calories: Int) async throws -> BackendUserCaloriesResponse {
        let req = BackendCreateUserCaloriesRequest(calories: calories)
        return try await post(path: "/api/v1/user/user-calories/create", body: req)
    }


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
                let raw = String(data: data, encoding: .utf8) ?? "No body"
                print("422 ERROR BODY:", raw)

                throw BackendError.apiError(errResponse.message ?? raw)
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
