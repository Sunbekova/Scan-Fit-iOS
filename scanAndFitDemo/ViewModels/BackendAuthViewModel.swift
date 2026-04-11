import Foundation
import Combine

@MainActor
final class BackendAuthViewModel: ObservableObject {

    @Published var state: AuthState = .loading
    @Published var errorMessage: String?
    @Published var isLoading = false

    @Published var pinSent = false
    @Published var pinVerified = false
    private(set) var resetToken = ""

    private let auth = BackendAuthService.shared
    private let userSvc = BackendUserService.shared
    private let tokens  = TokenManager.shared

    var displayName: String = ""

    init() {
        Task { await restoreSession() }
    }


    func restoreSession() async {
        guard tokens.isLoggedIn else { state = .unauthenticated; return }

        do {
            let me = try await userSvc.getMe()
            guard me.success, let userData = me.data else {
                await tryRefreshOrLogout(); return
            }
            displayName = userData.username ?? userData.email
            state = await resolveProfileState()
        } catch {
            await tryRefreshOrLogout()
        }
    }

    func login(email: String, password: String) async {
        guard validateFields(email: email, password: password) else { return }
        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        do {
            let resp = try await auth.login(email: email, password: password)
            guard resp.success, let d = resp.data else {
                errorMessage = resp.message ?? "Login failed"; return
            }
            tokens.saveAuth(d)
            displayName = email.components(separatedBy: "@").first ?? email
            state = await resolveProfileState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(name: String, email: String, password: String) async {
        guard !name.isEmpty else { errorMessage = "Please enter your name"; return }
        guard validateFields(email: email, password: password) else { return }
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let resp = try await auth.register(username: name, email: email, password: password)
            guard resp.success, let d = resp.data else {
                errorMessage = resp.message ?? "Registration failed"; return
            }
            tokens.saveAuth(d)
            displayName = name
            state = .profileIncomplete
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        Task {
            _ = try? await auth.logout()
            tokens.clearAll()
            state = .unauthenticated
        }
    }

    func forgotPassword(email: String) async {
        guard !email.isEmpty else { errorMessage = "Please enter your email"; return }
        isLoading = true; errorMessage = nil
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
            if resp.success==true, let d = resp.data { resetToken = d.token; pinVerified = true}
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
        UserDefaults.standard.set(true, forKey: "profile_completed_\(tokens.userId ?? 0)")
        state = .authenticated
    }

    private func resolveProfileState() async -> AuthState {
        let uid = tokens.userId ?? 0

        if UserDefaults.standard.bool(forKey: "profile_completed_\(uid)") {return .authenticated}
        do {
            let resp = try await userSvc.getMeasure()
            if resp.success, let data = resp.data,
               (data.height ?? 0) > 0 || !(data.age ?? "").isEmpty {
                UserDefaults.standard.set(true, forKey: "profile_completed_\(uid)")
                return .authenticated
            }
        } catch {}
        return .profileIncomplete
    }

    private func tryRefreshOrLogout() async {
        guard let rt = tokens.refreshToken else { tokens.clearAll(); state = .unauthenticated; return }
        do {
            let resp = try await auth.refreshToken(rt)
            if resp.success, let d = resp.data {
                tokens.saveAuth(d)
                state = await resolveProfileState()
            } else { tokens.clearAll(); state = .unauthenticated }
        } catch { tokens.clearAll(); state = .unauthenticated }
    }

    private func validateFields(email: String, password: String) -> Bool {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"; return false }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"; return false }
        return true
    }
}
