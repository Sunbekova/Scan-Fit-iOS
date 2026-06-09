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
        } catch let err as BackendError {
            switch err {
            case .sessionExpired:
                tokens.clearAll()
                state = .unauthenticated
            default:
                await tryRefreshOrLogout()
            }
        }catch {
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
                errorMessage = resp.message ?? "Login failed".localized; return
            }
            tokens.saveAuth(d)
            displayName = email.components(separatedBy: "@").first ?? email
            state = await resolveProfileState()
        } catch let err as BackendError {
            handleSessionError(err)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(name: String, email: String, password: String) async {
        guard validateSignUp(name: name, email: email, password: password) else { return }
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let resp = try await auth.register(username: name, email: email, password: password)
            if resp.success {
                errorMessage = "You are signed up. Please sign in.".localized
            } else {
                errorMessage = resp.message ?? "Registration failed".localized
            }
        } catch let err as BackendError {
            handleSessionError(err)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func forgotPassword(email: String) async {
        guard !email.isEmpty else { errorMessage = "Please enter your email".localized; return }
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let resp = try await auth.forgotPassword(email: email)
            if resp.success == true { pinSent = true }
            else { errorMessage = resp.message ?? "Could not send PIN".localized }
        } catch let err as BackendError {
            handleSessionError(err)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func verifyPin(email: String, pin: String) async {
        guard !pin.isEmpty else { errorMessage = "Please enter the PIN".localized; return }
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let resp = try await auth.verifyPin(email: email, pin: pin)
            if resp.success, let token = resp.data?.token {
                resetToken = token
                pinVerified = true
            } else {
                errorMessage = resp.message ?? "Invalid PIN".localized
            }
        } catch let err as BackendError {
            handleSessionError(err)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPassword(email: String, newPassword: String) async {
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters".localized; return
        }
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let resp = try await auth.resetPassword(email: email, token: resetToken, newPassword: newPassword)
            if resp.success == true {
                tokens.clearAll()
                state = .unauthenticated
            } else {
                errorMessage = resp.message ?? "Reset failed".localized
            }
        } catch let err as BackendError {
            handleSessionError(err)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    //role refresh
    func refreshRole() async {
        guard let resp = try? await userSvc.getUserRole(), resp.success,
              let role = resp.data?.code else { return }
        tokens.userRole = role
    }

    func signOut() {
        tokens.clearAll()
        state = .unauthenticated
    }

    func markProfileCompleted() {
        state = .authenticated
    }

    func handleSessionError(_ err: BackendError) {
        switch err {
        case .sessionExpired, .notAuthenticated:
            tokens.clearAll()
            state = .unauthenticated
        case .apiError(let msg):
            errorMessage = msg
        }
    }

    // MARK: - Private helpers

    private func validateFields(email: String, password: String) -> Bool {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields".localized; return false
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters".localized; return false
        }
        return true
    }

    private func validateSignUp(name: String, email: String, password: String) -> Bool {
        if name.isEmpty || email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields".localized; return false
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters".localized; return false
        }
        return true
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
            } else {
                tokens.clearAll(); state = .unauthenticated
            }
        } catch {
            tokens.clearAll(); state = .unauthenticated
        }
    }
}
