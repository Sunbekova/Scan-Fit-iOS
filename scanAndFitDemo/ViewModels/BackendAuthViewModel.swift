import Foundation
import Combine

@MainActor
final class BackendAuthViewModel: ObservableObject {

    @Published var user: BackendUserAccountData?
    @Published var state: AuthState = .loading
    @Published var errorMessage: String?
    @Published var isLoading = false

    @Published var pinSent = false
    @Published var pinVerified = false
    private(set) var resetToken = ""

    private let auth = BackendAuthService.shared
    private let userSvc = BackendUserService.shared
    private let tokens = TokenManager.shared

    var currentUser: BackendUserAccountData? { user }
    var userId: Int? { tokens.userId }
    var displayName: String { user?.username ?? user?.email ?? "User" }

    init() {
        Task { await restoreSession() }
    }


    func restoreSession() async {
        guard tokens.isLoggedIn else { state = .unauthenticated; return }
        do {
            let resp = try await userSvc.getMe()
            if resp.success == true, let data = resp.data {
                self.user = data
                tokens.userId = data.id
                await refreshUserRole()
                let completed = UserDefaults.standard.bool(forKey: "profile_completed")
                state = completed ? .authenticated : .profileIncomplete
            } else {
                await tryRefreshOrLogout()
            }
        } catch {
            await tryRefreshOrLogout()
        }
    }

    private func tryRefreshOrLogout() async {
        guard let refresh = tokens.refreshToken else { logout(); return }
        do {
            let resp = try await auth.refreshToken(refresh)
            if resp.success == true, let data = resp.data {
                tokens.saveAuth(data)
                let me = try await userSvc.getMe()
                if let userData = me.data {
                    self.user = userData
                    tokens.userId = userData.id
                }
                await refreshUserRole()
                let completed = UserDefaults.standard.bool(forKey: "profile_completed")
                state = completed ? .authenticated : .profileIncomplete
            } else {
                logout()
            }
        } catch { logout() }
    }

    private func refreshUserRole() async {
        do {
            let resp = try await userSvc.getUserRole()
            if let code = resp.data?.code {
                tokens.userRole = code.lowercased()
            }
        } catch {}
    }

    func login(email: String, password: String) async {
        guard validateFields(email: email, password: password) else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let resp = try await auth.login(email: email, password: password)
            if resp.success == true, let data = resp.data {
                tokens.saveAuth(data)
                let me = try await userSvc.getMe()
                if let userData = me.data { self.user = userData; tokens.userId = userData.id }
                await refreshUserRole()
                let completed = UserDefaults.standard.bool(forKey: "profile_completed")
                state = completed ? .authenticated : .profileIncomplete
            } else { errorMessage = resp.message ?? "Login failed" }
        } catch { errorMessage = error.localizedDescription }
    }

    func signUp(username: String, email: String, password: String) async {
        guard !username.isEmpty else { errorMessage = "Please enter a username"; return }
        guard validateFields(email: email, password: password) else { return }
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let resp = try await auth.register(username: username, email: email, password: password)
            if resp.success == true, let data = resp.data {
                tokens.saveAuth(data)
                let me = try await userSvc.getMe()
                if let userData = me.data { self.user = userData; tokens.userId = userData.id }
                await refreshUserRole()
                state = .profileIncomplete
            } else { errorMessage = resp.message ?? "Registration failed" }
        } catch { errorMessage = error.localizedDescription }
    }

    func signOut() {
        Task { _ = try? await auth.logout(); logout() }
    }

    private func logout() {
        tokens.clearAll()
        UserDefaults.standard.removeObject(forKey: "profile_completed")
        user = nil
        state = .unauthenticated
    }


    func forgotPassword(email: String) async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let resp = try await auth.forgotPassword(email: email)
            if resp.success == true { pinSent = true }
            else { errorMessage = resp.message ?? "Could not send PIN" }
        } catch { errorMessage = error.localizedDescription }
    }

    func verifyPin(email: String, pin: String) async {
        guard !pin.isEmpty else { errorMessage = "Please enter the PIN"; return }
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let resp = try await auth.verifyPin(email: email, pin: pin)
            if resp.success == true, let data = resp.data { resetToken = data.token; pinVerified = true }
            else { errorMessage = resp.message ?? "Invalid PIN" }
        } catch { errorMessage = error.localizedDescription }
    }

    func resetPassword(email: String, newPassword: String) async {
        guard newPassword.count >= 6 else { errorMessage = "Password must be at least 6 characters"; return }
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let resp = try await auth.resetPassword(email: email, token: resetToken, newPassword: newPassword)
            if resp.success == true { pinSent = false; pinVerified = false; resetToken = ""; state = .unauthenticated }
            else { errorMessage = resp.message ?? "Reset failed" }
        } catch { errorMessage = error.localizedDescription }
    }

    func markProfileCompleted() {
        UserDefaults.standard.set(true, forKey: "profile_completed")
        state = .authenticated
    }

    private func validateFields(email: String, password: String) -> Bool {
        guard !email.isEmpty, !password.isEmpty else { errorMessage = "Please fill in all fields"; return false }
        guard password.count >= 6 else { errorMessage = "Password must be at least 6 characters"; return false }
        return true
    }
}
