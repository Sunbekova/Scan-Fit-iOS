import Foundation

// Backend base: http://46.101.137.109:3000

actor BackendAuthService {
    static let shared = BackendAuthService()

    private let baseURL = "http://46.101.137.109:3000"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func register(username: String, email: String, password: String) async throws -> BackendAuthResponse {
        let body = BackendRegisterRequest(username: username, email: email,
                                         password: password, passwordConfirmation: password)
        return try await post(path: "/api/v1/auth/register", body: body)
    }

    func login(email: String, password: String) async throws -> BackendAuthResponse {
        let body = BackendLoginRequest(email: email, password: password)
        return try await post(path: "/api/v1/auth/login", body: body)
    }

    // POST /api/v1/auth/logout

    func logout() async throws -> BackendBaseResponse {
        if TokenManager.shared.bearerToken == nil {
            return BackendBaseResponse(message: nil, success: true)
        }
        return try await postAuthenticated(path: "/api/v1/auth/logout", body: EmptyBody())
    }

    func refreshToken(_ refreshToken: String) async throws -> BackendAuthResponse {
        let body = BackendRefreshTokenRequest(refreshToken: refreshToken)
        return try await post(path: "/api/v1/auth/refresh", body: body)
    }

    func forgotPassword(email: String) async throws -> BackendBaseResponse {
        let body = BackendForgotPasswordRequest(email: email)
        return try await post(path: "/api/v1/auth/password/forgot", body: body)
    }

    func verifyPin(email: String, pin: String) async throws -> BackendVerifyPinResponse {
        let body = BackendVerifyPinRequest(email: email, pinCode: pin)
        return try await post(path: "/api/v1/auth/password/verify-pin", body: body)
    }

    func resetPassword(email: String, token: String, newPassword: String) async throws -> BackendBaseResponse {
        let body = BackendResetPasswordRequest(email: email, token: token,
                                               newPassword: newPassword, newPasswordConfirmation: newPassword)
        return try await post(path: "/api/v1/auth/password/reset", body: body)
    }

    private struct EmptyBody: Encodable {}

    private func post<B: Encodable, R: Decodable>(path: String, body: B) async throws -> R {
        var request = try buildRequest(path: path, method: "POST")
        request.httpBody = try encoder.encode(body)
        return try await execute(request)
    }

    private func postAuthenticated<B: Encodable, R: Decodable>(path: String, body: B) async throws -> R {
        var request = try buildRequest(path: path, method: "POST", authenticated: true)
        request.httpBody = try encoder.encode(body)
        return try await execute(request)
    }

    private func buildRequest(path: String, method: String, authenticated: Bool = false) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {throw NetworkError.invalidURL}
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authenticated {
            guard let bearer = TokenManager.shared.bearerToken else {throw BackendError.notAuthenticated}
            request.setValue(bearer, forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {throw NetworkError.invalidResponse}
        guard (200..<300).contains(http.statusCode) else {
            if let errResponse = try? decoder.decode(BackendBaseResponse.self, from: data) {
                throw BackendError.apiError(errResponse.message ?? "Server error \(http.statusCode)")
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


enum BackendError: LocalizedError {
    case apiError(String)
    case notAuthenticated
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .apiError(let msg): return msg
        case .notAuthenticated: return "You must be logged in to perform this action"
        case .sessionExpired: return "Your session has expired. Please log in again."
        }
    }
}
