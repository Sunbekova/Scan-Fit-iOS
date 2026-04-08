import Foundation
import FirebaseAuth
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var state: AuthState = .loading
    @Published var errorMessage: String?
    @Published var isLoading = false

    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private let userDefaults = UserDefaults.standard

    init() {
        observeAuthState()
    }

    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }

    // MARK: - Auth State Observation

    private func observeAuthState() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let user = user {
                    let isComplete = self.userDefaults.bool(forKey: "profile_completed_\(user.uid)")
                    self.state = isComplete ? .authenticated : .profileIncomplete
                } else {
                    self.state = .unauthenticated
                }
            }
        }
    }

    // MARK: - Login

    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            // state updated by observer
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Sign Up

    func signUp(name: String, email: String, password: String) async {
        guard !email.isEmpty, password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            // state updated by observer
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Forgot Password

    func resetPassword(email: String) async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        try? Auth.auth().signOut()
    }

    // MARK: - Profile Completion

    var currentUser: User? {
        Auth.auth().currentUser
    }

    var displayName: String {
        currentUser?.displayName ?? "User"
    }

    func markProfileCompleted() {
        guard let uid = currentUser?.uid else { return }
        userDefaults.set(true, forKey: "profile_completed_\(uid)")
        state = .authenticated
    }
}
