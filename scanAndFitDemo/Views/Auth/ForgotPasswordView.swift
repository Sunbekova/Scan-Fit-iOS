import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var sent = false

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 48))
                    .foregroundColor(Color("AppGreen"))
                Text("Reset Password")
                    .font(.system(size: 28, weight: .bold))
                Text("Enter your email and we'll send a reset link")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            SFTextField(placeholder: "Email", text: $email, icon: "envelope")
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            if let error = authVM.errorMessage {
                Text(error).font(.caption).foregroundColor(.red)
            }

            if sent {
                Label("Reset link sent! Check your email.", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.subheadline)
            }

            SFPrimaryButton(title: sent ? "Resend Email" : "Send Reset Link", isLoading: authVM.isLoading) {
                Task {
                    await authVM.resetPassword(email: email)
                    if authVM.errorMessage == nil { sent = true }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").foregroundColor(Color("AppGreen"))
                }
            }
        }
    }
}
