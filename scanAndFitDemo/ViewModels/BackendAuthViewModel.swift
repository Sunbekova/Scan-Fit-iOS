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
        guard tokens.accessToken != nil || tokens.refreshToken != nil else {
            state = .unauthenticated; return
        }
        if tokens.isTokenExpired, let rt = tokens.refreshToken {
            do {
                let resp = try await auth.refreshToken(rt)
                if resp.success, let d = resp.data { tokens.saveAuth(d) }
                else { tokens.clearAll(); state = .unauthenticated; return }
            } catch { tokens.clearAll(); state = .unauthenticated; return }
        }

        guard tokens.bearerToken != nil else { state = .unauthenticated; return }

        do {
            let me = try await userSvc.getMe()
            guard me.success, let userData = me.data else {
                await tryRefreshOrLogout(); return
            }
            displayName = userData.username ?? userData.email
            state = await resolveProfileState()
        } catch let err as BackendError where err == BackendError.sessionExpired {
            tokens.clearAll(); state = .unauthenticated
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
        } catch { errorMessage = error.localizedDescription }
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
            errorMessage = "You are signed up. Please sign in."
            state = .unauthenticated
        } catch { errorMessage = error.localizedDescription }
    }

    func signOut() {
        Task {
            _ = try? await auth.logout()
            tokens.clearAll()
            state = .unauthenticated
        }
    }

    //profile bitu
    func markProfileCompleted() {
        let uid = tokens.userId ?? 0
        UserDefaults.standard.set(true, forKey: "profile_completed_\(uid)")
        // Also tell backend
        Task { _ = try? await userSvc.updateRegistrationStatus(isFinished: true) }
        state = .authenticated
    }

    func forgotPassword(email: String) async {
        guard !email.isEmpty else { errorMessage = "Please enter your email"; return }
        isLoading = true; errorMessage = nil; defer { isLoading = false }
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
            if resp.success == true {
                pinSent = false; pinVerified = false; resetToken = ""
                state = .unauthenticated
            } else { errorMessage = resp.message ?? "Reset failed" }
        } catch { errorMessage = error.localizedDescription }
    }
//role refresh
    func refreshRole() async {
        guard let resp = try? await userSvc.getUserRole(), resp.success,
              let role = resp.data?.code else { return }
        tokens.userRole = role
    }

    func handleSessionError(_ error: Error) {
        if let be = error as? BackendError, case .sessionExpired = be {
            tokens.clearAll()
            state = .unauthenticated
        }
    }

    private func resolveProfileState() async -> AuthState {
        let uid = tokens.userId ?? 0

        if UserDefaults.standard.bool(forKey: "profile_completed_\(uid)") {
            return .authenticated
        }
        if let statusResp = try? await userSvc.getRegistrationStatus(),
           statusResp.success,
           let finished = statusResp.data?.isFinishedRegister, finished {
            UserDefaults.standard.set(true, forKey: "profile_completed_\(uid)")
            return .authenticated
        }
        if let measureResp = try? await userSvc.getMeasure(),
           measureResp.success,
           let data = measureResp.data,
           (data.height ?? 0) > 0 || !(data.age ?? "").isEmpty {
            UserDefaults.standard.set(true, forKey: "profile_completed_\(uid)")
            return .authenticated
        }
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

extension BackendError: Equatable {
    static func == (lhs: BackendError, rhs: BackendError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthenticated, .notAuthenticated): return true
        case (.sessionExpired, .sessionExpired):     return true
        case (.apiError(let a), .apiError(let b)):   return a == b
        default: return false
        }
    }
}
