import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject private var authVM: BackendAuthViewModel
    @Environment(\.dismiss) private var dismiss
    private let userDefaults = UserDefaults.standard

    private var uid: Int { authVM.currentUser?.id ?? 0 }
    private var email: String { authVM.currentUser?.email ?? "—" }
    private var displayName: String { authVM.displayName }
    private var height: String { userDefaults.string(forKey: "user_height_\(uid)") ?? "—" }
    private var weight: String { userDefaults.string(forKey: "user_weight_\(uid)") ?? "—" }
    private var birthdate: String { userDefaults.string(forKey: "user_birthdate_\(uid)") ?? "—" }
    private var gender: String { userDefaults.string(forKey: "user_gender_\(uid)") ?? "—" }
    private var diseases: [String] { userDefaults.stringArray(forKey: "user_diseases") ?? [] }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Circle()
                        .fill(Color("AppGreen").opacity(0.15))
                        .frame(width: 88, height: 88)
                        .overlay(
                            Text(String(authVM.displayName.prefix(1)).uppercased())
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color("AppGreen"))
                        )
                    Text(displayName)
                    Text(email)
                        .font(.title2).fontWeight(.bold)
                    Text(String(displayName.prefix(1)).uppercased())                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.top, 16)

                HStack(spacing: 0) {
                    StatItem(label: "Height", value: "\(height) cm")
                    Divider()
                    StatItem(label: "Weight", value: "\(weight) kg")
                    Divider()
                    StatItem(label: "Born", value: birthdate)
                }
                .frame(height: 70)
                .background(Color(.systemGray6))
                .cornerRadius(14)

                if !diseases.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Health Conditions")
                            .font(.headline)
                        FlowLayout(spacing: 8) {
                            ForEach(diseases, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color("AppGreen").opacity(0.15))
                                    .foregroundColor(Color("AppGreen"))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
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
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Profile")
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

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.subheadline).fontWeight(.semibold)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}


struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var x: CGFloat = 0, y: CGFloat = 0, maxHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0; y += maxHeight + spacing; maxHeight = 0
            }
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: width, height: y + maxHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, maxHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += maxHeight + spacing; maxHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
    }
}
