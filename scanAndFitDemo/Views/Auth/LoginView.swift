import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var navigateToSignUp = false
    @State private var navigateToForgot = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "barcode.viewfinder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundColor(Color("AppGreen"))
                    Text("Welcome Back")
                        .font(.system(size: 28, weight: .bold))
                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 48)

                // Fields
                VStack(spacing: 16) {
                    SFTextField(placeholder: "Email", text: $email, icon: "envelope")
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)

                    SFSecureField(placeholder: "Password", text: $password, showPassword: $showPassword)
                        .textContentType(.password)
                }

                // Forgot password
                HStack {
                    Spacer()
                    Button("Forgot Password?") { navigateToForgot = true }
                        .font(.footnote)
                        .foregroundColor(Color("AppGreen"))
                }

                // Error
                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                // Login button
                SFPrimaryButton(title: "Sign In", isLoading: authVM.isLoading) {
                    Task { await authVM.login(email: email, password: password) }
                }

                // Sign up link
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    Button("Sign Up") { navigateToSignUp = true }
                        .foregroundColor(Color("AppGreen"))
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToSignUp) { SignUpView() }
        .navigationDestination(isPresented: $navigateToForgot) { ForgotPasswordView() }
    }
}
