import SwiftUI

struct VerifyPinView: View {
    let email: String
    @ObservedObject var authVM: BackendAuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var digits = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    @State private var showResetPassword = false
    
    private var pinCode: String { digits.joined() }
    private var isComplete: Bool { digits.allSatisfy { $0.count == 1 } }
    
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
                        Text("Enter the 6-digit verification code sent to ")
                        + Text(email)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    
                    Spacer().frame(height: 40)
                    
                    HStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { i in
                            pinBox(index: i)
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
                        Task { await authVM.verifyPin(email: email, pin: pinCode) }
                    } label: {
                        if authVM.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Verify & Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(!isComplete ? appBlue.opacity(0.6) : appBlue)
                    .cornerRadius(28)
                    .shadow(color: appBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                    .disabled(!isComplete || authVM.isLoading)
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
    
    
    @ViewBuilder
    private func pinBox(index: Int) -> some View {
        TextField("", text: $digits[index])
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .multilineTextAlignment(.center)
            .font(.title2.monospacedDigit().bold())
            .frame(width: 44, height: 52)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(focusedIndex == index ? appBlue : Color.clear, lineWidth: 2)
            )
            .focused($focusedIndex, equals: index)
            .onChange(of: digits[index]) { val in
                if val.count > 1 { digits[index] = String(val.last!) }
                if digits[index].count == 1, index < 5 { focusedIndex = index + 1 }
                if digits[index].isEmpty, index > 0 { focusedIndex = index - 1 }
            }
            .onAppear {
                if index == 0 { focusedIndex = 0 }
            }
    }
}
