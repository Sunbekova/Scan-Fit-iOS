import SwiftUI

struct VerifyPinView: View {
    let email: String
    @ObservedObject var authVM: BackendAuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var pin = ""
    @State private var showResetPassword = false
    
    let appBlue = Color("AppGreen")
    let appLinkOrange = Color(red: 0.95, green: 0.35, blue: 0.15)
    
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
                    
                    Text("Verify PIN")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.2))
                    
                    Spacer().frame(height: 12)
                    
                    Group {
                        Text("Enter the6-digit verification code sent to ")
                        + Text(email)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    
                    Spacer().frame(height: 40)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<6) { index in
                            if let digitChar = pin.indices.contains(pin.index(pin.startIndex, offsetBy: index)) ? pin[pin.index(pin.startIndex, offsetBy: index)] : nil {
                                Text(String(digitChar))
                                    .frame(width: 48, height: 56)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .font(.title2.monospacedDigit().bold())
                                    .foregroundColor(.primary)
                            } else {
                                Text(" ")
                                    .frame(width: 48, height: 56)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    if let error = authVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 16)
                    }
                    
                    Spacer().frame(height: 32)
                    
                    Button {
                        Task { await authVM.verifyPin(email: email, pin: pin) }
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
                    .background(pin.count < 4 ? appBlue.opacity(0.6) : appBlue)
                    .cornerRadius(28)
                    .shadow(color: appBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                    .disabled(pin.count < 4 || authVM.isLoading)
                    .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 32)
                    
                    HStack(spacing: 4) {
                        Text("Didn't receive the code?")
                            .foregroundColor(.secondary)
                        
                        Button {
                            Task { await authVM.forgotPassword(email: email) }
                        } label: {
                            Text("Resend")
                                .fontWeight(.bold)
                                .foregroundColor(appLinkOrange)
                        }
                    }
                    .font(.system(size: 15))
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onChange(of: authVM.pinVerified) { verified in
                if verified { showResetPassword = true }
            }
            .navigationDestination(isPresented: $showResetPassword) {
                ResetPasswordView(email: email, authVM: authVM)
            }
        }
    }
}

// MARK: - ResetPassword

struct ResetPasswordView: View {
    let email: String
    @ObservedObject var authVM: BackendAuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    let appCornerRadius: CGFloat = 28
    
    
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
                    CleanSecureField(placeholder: "Confirm new password", text: $confirmPassword)
                }
                .padding(.horizontal, 24)
                
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
                .background(Color("AppGreen"))
                .cornerRadius(appCornerRadius)
                .shadow(color: Color("AppGreen").opacity(0.3), radius: 10, x: 0, y: 5)
                .disabled(!canSubmit || authVM.isLoading)
                .padding(.horizontal, 24)
                
                Spacer()            }
        }
        .navigationBarHidden(true)
        .onChange(of: authVM.state) { newState in
            if newState == .unauthenticated {
                dismiss()
            }
        }
    }
    
    private var canSubmit: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }
}
