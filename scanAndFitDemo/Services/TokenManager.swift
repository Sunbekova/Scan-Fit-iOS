import Foundation
import Security

final class TokenManager {
    static let shared = TokenManager()
    private init() {}

    private let service = "com.scanfit.app"

    private enum Key: String {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case userId = "user_id"
        case userRole = "user_role"
        case expiresAt = "expires_at"
    }

    var accessToken: String? {
        get { load(key: .accessToken) }
        set {
            if let v = newValue { save(key: .accessToken, value: v) }
            else { delete(key: .accessToken) }
        }
    }

    var refreshToken: String? {
        get { load(key: .refreshToken) }
        set {
            if let v = newValue { save(key: .refreshToken, value: v) }
            else { delete(key: .refreshToken) }
        }
    }

    var userId: Int? {
        get { load(key: .userId).flatMap { Int($0) } }
        set {
            if let v = newValue { save(key: .userId, value: String(v)) }
            else { delete(key: .userId) }
        }
    }

    var userRole: String? {
        get { load(key: .userRole) }
        set {
            if let v = newValue { save(key: .userRole, value: v) }
            else { delete(key: .userRole) }
        }
    }

    var expiresAt: Double? {
        get { load(key: .expiresAt).flatMap { Double($0) } }
        set {
            if let v = newValue { save(key: .expiresAt, value: String(v)) }
            else { delete(key: .expiresAt) }
        }
    }

    var isVip: Bool { userRole?.lowercased() == "vip" }

    var bearerToken: String? {
        guard let token = accessToken else { return nil }
        return "Bearer \(token)"
    }

    var isLoggedIn: Bool {
        guard accessToken != nil else { return false }
        if let exp = expiresAt, Date().timeIntervalSince1970 > exp - 60 {
            // Token is expired or expiring in <60s – caller should refresh
            return refreshToken != nil
        }
        return true
    }

    var isTokenExpired: Bool {
        guard accessToken != nil else { return true }
        guard let exp = expiresAt else { return false }
        return Date().timeIntervalSince1970 >= exp - 60
    }

    func saveAuth(_ data: BackendAuthData) {
        accessToken = data.accessToken
        refreshToken = data.refreshToken
        userId = data.id
        if let roleCode = data.role?.code { userRole = roleCode }
        let expiry = Date().timeIntervalSince1970 + Double(data.expiresIn)
        expiresAt = expiry
    }

    func clearAll() {
        accessToken = nil
        refreshToken = nil
        userId = nil
        userRole = nil
        expiresAt = nil
    }

    private func save(key: Key, value: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
            kSecValueData: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func load(key: Key) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    private func delete(key: Key) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }
}
