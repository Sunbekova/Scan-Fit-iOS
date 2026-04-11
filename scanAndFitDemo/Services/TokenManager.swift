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
    }

    var accessToken: String? {
        get { load(key: .accessToken) }
        set { newValue.map { save(key: .accessToken, value: $0) } ?? delete(key: .accessToken) }
    }

    var refreshToken: String? {
        get { load(key: .refreshToken) }
        set { newValue.map { save(key: .refreshToken, value: $0) } ?? delete(key: .refreshToken) }
    }

    var userId: Int? {
        get { load(key: .userId).flatMap { Int($0) } }
        set { newValue.map { save(key: .userId, value: String($0)) } ?? delete(key: .userId) }
    }

    var userRole: String? {
        get { load(key: .userRole) }
        set { newValue.map { save(key: .userRole, value: $0) } ?? delete(key: .userRole) }
    }

    var isVip: Bool { userRole?.lowercased() == "vip" }

    var bearerToken: String? {
        guard let token = accessToken else { return nil }
        return "Bearer \(token)"
    }

    var isLoggedIn: Bool { accessToken != nil }

    func saveAuth(_ data: BackendAuthData) {
        accessToken = data.accessToken
        refreshToken = data.refreshToken
        userId = data.id
        if let roleCode = data.role?.code { userRole = roleCode }
    }

    func clearAll() {
        accessToken = nil
        refreshToken = nil
        userId = nil
        userRole = nil
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
