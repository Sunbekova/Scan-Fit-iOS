import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject private var authVM: BackendAuthViewModel
    @StateObject private var profileVM = UserProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: ProfileTab = .account

    enum ProfileTab: String, CaseIterable {
        case account = "Account"
        case measurements = "Measurements"
        case dietary = "Dietary"
        case diseases = "Diseases"
    }

    var body: some View {
        VStack(spacing: 0) {
            profileHeader
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ProfileTab.allCases, id: \.self) { tab in
                        Button(tab.rawValue) { selectedTab = tab }
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .bold : .regular)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(selectedTab == tab ? Color("AppGreen") : Color(.systemGray5))
                            .foregroundColor(selectedTab == tab ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 8)

            Divider()

            if profileVM.isLoading {
                Spacer(); ProgressView(); Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        switch selectedTab {
                        case .account:
                            AccountSection(profileVM: profileVM, authVM: authVM)
                        case .measurements:
                            MeasurementsSection(profileVM: profileVM)
                                .environmentObject(authVM)
                        case .dietary:
                            DietarySection(profileVM: profileVM)
                        case .diseases:
                            DiseasesSection(profileVM: profileVM)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").foregroundColor(Color("AppGreen"))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { Task { await profileVM.refreshTodayCalories() } } label: {
                    Image(systemName: "arrow.clockwise").foregroundColor(Color("AppGreen"))
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { profileVM.errorMessage != nil },
            set: { if !$0 { profileVM.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { profileVM.errorMessage = nil }
        } message: { Text(profileVM.errorMessage ?? "") }
        .task { await profileVM.loadAll() }
    }

    private var profileHeader: some View {
        HStack(spacing: 16) {
            Group {
                if let photoURL = profileVM.photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                                .frame(width: 64, height: 64).clipShape(Circle())
                        default: defaultProfileAvatar
                        }
                    }
                } else { defaultProfileAvatar }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(profileVM.username.isEmpty ? "User" : profileVM.username)
                    .font(.title3).fontWeight(.bold)
                Text(profileVM.email)
                    .font(.subheadline).foregroundColor(.secondary)
                let roleText = TokenManager.shared.userRole == "vip" ? "ScanFit Pro" : "Basic"
                Text(roleText)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(roleText == "ScanFit Pro" ? Color(hex: "#FBBF24") : .secondary)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background((roleText == "ScanFit Pro" ? Color(hex: "#0F172A") : Color.gray)
                        .opacity(roleText == "ScanFit Pro" ? 1.0 : 0.1))
                    .cornerRadius(10)
            }
            Spacer()
        }
    }

    private var defaultProfileAvatar: some View {
        Circle()
            .fill(Color("AppGreen").opacity(0.15))
            .frame(width: 64, height: 64)
            .overlay(
                Text(String((profileVM.username.isEmpty ? profileVM.email : profileVM.username).prefix(1)).uppercased())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color("AppGreen"))
            )
    }
}
