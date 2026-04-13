import Foundation

// /api/v1/user/* endpoints

actor BackendUserService {
    static let shared = BackendUserService()

    private let baseURL = "http://46.101.137.109:3000"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 180
        config.timeoutIntervalForResource = 240
        return URLSession(configuration: config)
    }()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    //user
    func getMe() async throws -> BackendUserAccountResponse { try await get(path: "/api/v1/user/me") }
    func getUserRole() async throws -> BackendUserRoleResponse { try await get(path: "/api/v1/user/me/role") }
    func getUserDetails() async throws -> BackendUserDetailsResponse { try await get(path: "/api/v1/user/me/details") }

    //measures
    func createMeasure(_ req: BackendUserMeasureRequest) async throws -> BackendUserMeasureResponse {
        try await post(path: "/api/v1/user/measure/create", body: req)
    }
    func getMeasure() async throws -> BackendUserMeasureResponse {
        try await get(path: "/api/v1/user/measure/get")
    }
    func updateMeasure(_ req: BackendUpdateUserMeasureRequest) async throws -> BackendUserMeasureResponse {
        try await put(path: "/api/v1/user/measure/update", body: req)
    }

    // diet preferen health
    func getDietTypes() async throws -> BackendDietTypeListResponse  { try await get(path: "/api/v1/user/diet-type/list") }
    func updateDietType(id: Int, isActive: Bool) async throws -> BackendUpdateDietTypeResponse {
        try await put(path: "/api/v1/user/diet-type/update/\(id)", body: BackendUpdateDietTypeRequest(isActive: isActive))
    }
    func getDietaryPreferences() async throws -> BackendDietTypeListResponse  { try await get(path: "/api/v1/user/dietary-preference/list") }
    func updateDietaryPreference(id: Int, isActive: Bool) async throws -> BackendUpdateDietTypeResponse {
        try await put(path: "/api/v1/user/dietary-preference/update/\(id)", body: BackendUpdateDietTypeRequest(isActive: isActive))
    }
    func getHealthConditions() async throws -> BackendDietTypeListResponse { try await get(path: "/api/v1/user/health-condition/list") }
    func updateHealthCondition(id: Int, isActive: Bool) async throws -> BackendUpdateDietTypeResponse {
        try await put(path: "/api/v1/user/health-condition/update/\(id)", body: BackendUpdateDietTypeRequest(isActive: isActive))
    }

    //diseases
    func getDiseases() async throws -> BackendDiseaseListResponse { try await get(path: "/api/v1/user/disease/list") }
    func getDiseaseLevels() async throws -> BackendDiseaseLevelListResponse { try await get(path: "/api/v1/user/disease-level/list") }
    func updateDisease(id: Int, diseaseLevelId: Int, isActive: Bool) async throws -> BackendUpdateDietTypeResponse {
        try await put(path: "/api/v1/user/disease/update/\(id)",
                      body: BackendUpdateDiseaseRequest(diseaseLevelId: diseaseLevelId, isActive: isActive))
    }

    //weight
    func getWeightManagement() async throws -> BackendWeightManagementResponse { try await get(path: "/api/v1/user/weight-management/get") }
    func updateWeightManagement(_ req: BackendUpdateWeightManagementRequest) async throws -> BackendUpdateDietTypeResponse {
        try await put(path: "/api/v1/user/weight-management/update", body: req)
    }

    //calories
    func getTodayCalories() async throws -> BackendUserCaloriesResponse { try await get(path: "/api/v1/user/user-calories/today") }
    func getCaloriesByDay(day: String) async throws -> BackendUserCaloriesResponse { try await get(path: "/api/v1/user/user-calories?day=\(day)") }
    func updateUserCalories(day: String, req: BackendUpdateUserCaloriesRequest) async throws -> BackendUserCaloriesResponse {
        try await putWithQuery(path: "/api/v1/user/user-calories/update", query: "day=\(day)", body: req)
    }
    func refreshTodayCalories() async throws -> BackendUserCaloriesResponse {
        try await put(path: "/api/v1/user/user-calories/today/refresh", body: EmptyBody())}
    func getUserCaloriesFirstDay() async throws -> BackendUserFirstDayResponse { try await get(path: "/api/v1/user/user-calories/first-day")}
    func getConsumptionHistory(from: String, to: String) async throws -> BackendConsumptionHistoryResponse {
        try await get(path: "/api/v1/users/me/consumption/history?from=\(from)&to=\(to)")
    }

    //water
    func getTodayWater() async throws -> BackendUserWaterResponse { try await get(path: "/api/v1/user/user-water/today") }
    func getWaterByDay(day: String) async throws -> BackendUserWaterResponse { try await get(path: "/api/v1/user/user-water?day=\(day)") }
    func updateWater(day: String, water: Int) async throws -> BackendUserWaterResponse {
        try await putWithQuery(path: "/api/v1/user/user-water/update", query: "day=\(day)",
                               body: BackendUpdateUserWaterRequest(water: water))
    }

    //daily eat / product scans
    func createUserDailyEat(_ req: BackendCreateUserDailyEatRequest) async throws -> BackendCreateUserDailyEatResponse {
        try await post(path: "/api/v1/product/user-daily-eat/create", body: req)
    }
    func createProductScan(_ req: BackendCreateProductScanRequest) async throws -> BackendCreateProductScanResponse {
        try await post(path: "/api/v1/product/product-scans/create", body: req)
    }
    func updateProductScan(id: Int, _ req: BackendCreateProductScanRequest) async throws -> BackendCreateProductScanResponse {
        try await put(path: "/api/v1/product/product-scans/update/\(id)", body: req)
    }
    func getProductScanByName(productName: String) async throws -> BackendProductScanResponse {
        let encoded = productName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? productName
        return try await get(path: "/api/v1/product/product-scans/get-by-product-name?product_name=\(encoded)")
    }
    func getProductScanLimit() async throws -> BackendProductScanLimitResponse        { try await get(path: "/api/v1/product/product-scans/limit") }
    func decreaseProductScanLimit() async throws -> BackendProductScanLimitDecreaseResponse {
        try await post(path: "/api/v1/product/product-scans/limit/decrease", body: EmptyBody())
    }

    //registr status
    func getRegistrationStatus() async throws -> BackendRegistrationStatusResponse {
        try await get(path: "/api/v1/user/registration-status/me")
    }
    func updateRegistrationStatus(isFinished: Bool) async throws -> BackendBaseResponse {
        try await put(path: "/api/v1/user/registration-status/me",
                      body: BackendUpdateRegistrationStatusRequest(isFinishedRegister: isFinished))
    }

    //profile img
    func changeProfilePicture(imageData: Data, filename: String) async throws -> BackendBaseResponse {
        guard let url = URL(string: baseURL + "/api/v1/user/change-picture") else { throw NetworkError.invalidURL }
        guard let bearer = TokenManager.shared.bearerToken else { throw BackendError.notAuthenticated }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(bearer, forHTTPHeaderField: "Authorization")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NetworkError.invalidResponse
        }
        return try decoder.decode(BackendBaseResponse.self, from: data)
    }

    private struct EmptyBody: Codable {}

    private func get<R: Decodable>(path: String) async throws -> R {
        let req = try buildRequest(path: path, method: "GET")
        return try await execute(req)
    }
    private func post<B: Encodable, R: Decodable>(path: String, body: B) async throws -> R {
        var req = try buildRequest(path: path, method: "POST")
        req.httpBody = try encoder.encode(body)
        return try await execute(req)
    }
    private func put<B: Encodable, R: Decodable>(path: String, body: B) async throws -> R {
        var req = try buildRequest(path: path, method: "PUT")
        req.httpBody = try encoder.encode(body)
        return try await execute(req)
    }
    private func putWithQuery<B: Encodable, R: Decodable>(path: String, query: String, body: B) async throws -> R {
        var req = try buildRequest(path: "\(path)?\(query)", method: "PUT")
        req.httpBody = try encoder.encode(body)
        return try await execute(req)
    }

    private func buildRequest(path: String, method: String) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let bearer = TokenManager.shared.bearerToken else { throw BackendError.notAuthenticated }
        request.setValue(bearer, forHTTPHeaderField: "Authorization")
        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest, isRetry: Bool = false) async throws -> T {
        if !isRetry && TokenManager.shared.isTokenExpired {
            await refreshTokenIfPossible()
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

        if http.statusCode == 401 && !isRetry {
            let refreshed = await refreshTokenIfPossible()
            if refreshed {
                var retried = request
                if let bearer = TokenManager.shared.bearerToken {
                    retried.setValue(bearer, forHTTPHeaderField: "Authorization")
                }
                return try await execute(retried, isRetry: true)
            }
            await MainActor.run { TokenManager.shared.clearAll() }
            throw BackendError.sessionExpired
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

    @discardableResult
    private func refreshTokenIfPossible() async -> Bool {
        guard let rt = TokenManager.shared.refreshToken else { return false }
        do {
            let resp = try await BackendAuthService.shared.refreshToken(rt)
            if resp.success, let d = resp.data {
                TokenManager.shared.saveAuth(d)
                return true
            }
        } catch {}
        return false
    }
}
