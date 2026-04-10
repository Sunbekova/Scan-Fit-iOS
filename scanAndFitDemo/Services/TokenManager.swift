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
    }


    var accessToken: String? {
        get { load(key: .accessToken) }
        set {
            if let value = newValue { save(key: .accessToken, value: value) }
            else { delete(key: .accessToken) }
        }
    }

    var refreshToken: String? {
        get { load(key: .refreshToken) }
        set {
            if let value = newValue { save(key: .refreshToken, value: value) }
            else { delete(key: .refreshToken) }
        }
    }

    var userId: Int? {
        get {
            guard let str = load(key: .userId) else { return nil }
            return Int(str)
        }
        set {
            if let value = newValue { save(key: .userId, value: String(value)) }
            else { delete(key: .userId) }
        }
    }


    var bearerToken: String? {
        guard let token = accessToken else { return nil }
        return "Bearer \(token)"
    }

    var isLoggedIn: Bool {
        accessToken != nil
    }

    func saveAuth(_ data: BackendAuthData) {
        accessToken = data.accessToken
        refreshToken = data.refreshToken
        userId = data.id
    }

    func clearAll() {
        accessToken = nil
        refreshToken = nil
        userId = nil
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
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8) else {
            return nil
        }
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
