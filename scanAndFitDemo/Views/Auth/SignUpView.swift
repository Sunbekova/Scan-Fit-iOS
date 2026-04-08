import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.system(size: 28, weight: .bold))
                    Text("Start your health journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)

                VStack(spacing: 16) {
                    SFTextField(placeholder: "Full Name", text: $name, icon: "person")
                        .textContentType(.name)

                    SFTextField(placeholder: "Email", text: $email, icon: "envelope")
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)

                    SFSecureField(placeholder: "Password (min 6 chars)", text: $password, showPassword: $showPassword)
                        .textContentType(.newPassword)
                }

                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                SFPrimaryButton(title: "Create Account", isLoading: authVM.isLoading) {
                    Task { await authVM.signUp(name: name, email: email, password: password) }
                }

                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)
                    Button("Sign In") { dismiss() }
                        .foregroundColor(Color("AppGreen"))
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color("AppGreen"))
                }
            }
        }
    }
}
