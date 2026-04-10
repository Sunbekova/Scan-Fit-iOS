import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var authVM = BackendAuthViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var showVerifyPin = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                Image(AppImages.mascot)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.bottom, 40)

                VStack(spacing: 12) {
                    Text("Forgot Password")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.2))

                    Text("Enter your email and we'll send a 6-digit verification PIN.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)

                TextField("Email address", text: $email)
                    .padding()
                    .frame(height: 55)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal, 24)

                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }

                Button {
                    Task { await authVM.forgotPassword(email: email) }
                } label: {
                    ZStack {
                        if authVM.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send PIN")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        Color("AppGreen")
                            .cornerRadius(27.5)
                            .shadow(color: Color("AppGreen").opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                }
                .disabled(email.isEmpty || authVM.isLoading)
                .padding(.horizontal, 24)
                .padding(.top, 30)

                HStack(spacing: 4) {
                    Text("Remembered your password?")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Sign in")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.1))
                    }
                }
                .padding(.top, 40)

                Spacer()
                Spacer()
            }
            .background(Color.white.ignoresSafeArea())
            
            .onChange(of: authVM.pinSent) { sent in
                if sent { showVerifyPin = true }
            }
            .navigationDestination(isPresented: $showVerifyPin) {
                VerifyPinView(email: email, authVM: authVM)
            }
        }
    }
}
