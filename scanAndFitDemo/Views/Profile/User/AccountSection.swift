import SwiftUI

struct AccountSection: View {
    let profileVM: UserProfileViewModel
    let authVM: BackendAuthViewModel

    var body: some View {
        VStack(spacing: 20) {

            HStack(spacing: 0) {
                StatItem(label: "Height", value: profileVM.height > 0 ? "\(profileVM.height) cm" : "—")
                Divider()
                StatItem(label: "Weight", value: profileVM.weight > 0 ? "\(profileVM.weight) kg" : "—")
                Divider()
                StatItem(label: "BMI", value: profileVM.bmiString)
            }
            .frame(height: 70)
            .background(Color(.systemGray6))
            .cornerRadius(14)

            let activeTags = (profileVM.healthConditions.filter(\.isActive).map(\.name)
                             + profileVM.diseases.filter(\.isActive).map(\.name))

            if !activeTags.isEmpty {
                sectionCard(title: "Health Conditions") {
                    FlowLayout(spacing: 8) {
                        ForEach(activeTags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color("AppGreen").opacity(0.15))
                                .foregroundColor(Color("AppGreen"))
                                .cornerRadius(20)
                        }
                    }
                }
            }

            let activeDiets = profileVM.dietTypes.filter(\.isActive).map(\.name)

            if !activeDiets.isEmpty {
                sectionCard(title: "Diet Preferences") {
                    FlowLayout(spacing: 8) {
                        ForEach(activeDiets, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(20)
                        }
                    }
                }
            }

            Button(role: .destructive) {
                authVM.signOut()
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(14)
            }
            .padding(.top, 8)
        }
        .padding(.top, 16)
    }
}
