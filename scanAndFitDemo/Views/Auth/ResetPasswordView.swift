import SwiftUI

struct ResetPasswordView: View {
    let email: String
    @ObservedObject var authVM: BackendAuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showNew = false
    @State private var showConfirm = false
    
    let appCornerRadius: CGFloat = 28
    
    private var passwordsMatch: Bool { !newPassword.isEmpty && newPassword == confirmPassword }
    private var canSubmit: Bool { newPassword.count >= 6 && passwordsMatch }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer().frame(height: 60)
                
                Image(AppImages.mascot)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 120)
                
                Spacer().frame(height: 40)
                
                Text("Reset Password")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.2))
                
                Spacer().frame(height: 12)
                
                Text("Create a new password that is different from previous passwords.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer().frame(height: 40)
                
                VStack(spacing: 16) {
                    CleanSecureField(placeholder: "New password", text: $newPassword)
                        .textContentType(.newPassword)
                    
                    CleanSecureField(placeholder: "Confirm new password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                .padding(.horizontal, 24)
                
                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
                
                if let error = authVM.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 16)
                }
                
                Spacer().frame(height: 32)
                
                Button {
                    Task { await authVM.resetPassword(email: email, newPassword: newPassword) }
                } label: {
                    if authVM.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Reset Password")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(canSubmit ? Color("AppGreen") : Color("AppGreen").opacity(0.6))
                .cornerRadius(appCornerRadius)
                .shadow(color: Color("AppGreen").opacity(0.3), radius: 10, x: 0, y: 5)
                .disabled(!canSubmit || authVM.isLoading)
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onChange(of: authVM.state) { newState in
            if newState == .unauthenticated {
                dismiss()
            }
        }
    }
}
