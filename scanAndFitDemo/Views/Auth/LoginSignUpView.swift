import SwiftUI

struct SFInputField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
            }
        }
        .font(.system(size: 16))
        .padding()
        .frame(height: 56)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}


struct LoginView: View {
    @EnvironmentObject var authVM: BackendAuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    @State private var showSignUp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    
                    Image(AppImages.mascot)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 120)
                    
                    Spacer().frame(height: 40)
                    
                    Text("Welcome Back")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.2))
                    
                    Spacer().frame(height: 40)
                    
                    VStack(spacing: 16) {
                        SFInputField(placeholder: "Email", text: $email, keyboardType: .emailAddress)
                        
                        SFInputField(placeholder: "Password", text: $password, isSecure: true)
                    }
                    .padding(.horizontal, 24)
                    
                    if let error = authVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                    }
                    
                    Spacer().frame(height: 32)
                    
                    SFPrimaryButton(title: "Login", isLoading: authVM.isLoading) {
                        Task { await authVM.login(email: email, password: password) }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 32)
                    
                    Button(action: { showForgotPassword = true }) {
                        Text("Forgot Password?")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer().frame(height: 12)
                    
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        
                        Button(action: { showSignUp = true }) {
                            Text("Sign up")
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.15))
                        }
                    }
                    .font(.system(size: 15))
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
                    .environmentObject(authVM)
            }
        }
    }
}

// MARK: - SignUpView

struct SignUpView: View {
    @EnvironmentObject var authVM: BackendAuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)
                    
                    Image(AppImages.mascot)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 120)
                    
                    Spacer().frame(height: 40)
                    
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.2))
                    
                    Spacer().frame(height: 40)
                    
                    VStack(spacing: 16) {
                        SFInputField(placeholder: "Name", text: $username)
                        
                        SFInputField(placeholder: "Email", text: $email, keyboardType: .emailAddress)
                        
                        SFInputField(placeholder: "Password", text: $password, isSecure: true)
                        
                        SFInputField(placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                    }
                    .padding(.horizontal, 24)
                    
                    if let error = authVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                    }
                    
                    Spacer().frame(height: 32)
                    
                    SFPrimaryButton(title: "Register", isLoading: authVM.isLoading) {
                        Task { await authVM.signUp(username: username, email: email, password: password) }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 32)
                    
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)
                        
                        Button(action: { dismiss() }) {
                            Text("Sign In")
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.15))
                        }
                    }
                    .font(.system(size: 15))
                    
                    Spacer()                }
            }
            .navigationBarHidden(true)
        }
    }
}
