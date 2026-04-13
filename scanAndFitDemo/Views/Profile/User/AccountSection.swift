import SwiftUI
import PhotosUI

struct AccountSection: View {
    @ObservedObject var profileVM: UserProfileViewModel
    let authVM: BackendAuthViewModel
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var photoUploadError: String?
    @State private var navigateToPro = false

    private let isVip = TokenManager.shared.isVip
    
    private var activeTags: [String] {
        (profileVM.healthConditions.filter(\.isActive).compactMap(\.name)
         + profileVM.diseases.filter(\.isActive).compactMap(\.name))
    }

    private var activeDiets: [String] {
        profileVM.dietTypes.filter(\.isActive).compactMap(\.name)
    }

    var body: some View {
        VStack(spacing: 20) {

            avatarSection
            proCard
            healthConditionsSection
            dietSection
            refreshButton
            signOutButton
            
        }
        .padding(.top, 16)
        .onChange(of: selectedPhoto) { _, item in
            Task { await uploadPhoto(item: item) }
        }
        .alert("Photo Upload Error", isPresented: Binding(
            get: { photoUploadError != nil },
            set: { if !$0 { photoUploadError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(photoUploadError ?? "")
        }
        .navigationDestination(isPresented: $navigateToPro) {
            ProSubscriptionView()
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let photoURL = profileVM.photoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                                    .frame(width: 84, height: 84).clipShape(Circle())
                            default:
                                defaultAvatar
                            }
                        }
                    } else {
                        defaultAvatar
                    }
                }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ZStack {
                        Circle().fill(Color("AppGreen")).frame(width: 28, height: 28)
                        Image(systemName: isUploadingPhoto ? "arrow.triangle.2.circlepath" : "camera.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
                .disabled(isUploadingPhoto)
            }

            Text("Change Photo")
                .font(.caption)
                .foregroundColor(Color("AppGreen"))
        }
        .frame(maxWidth: .infinity)
    }

    private var defaultAvatar: some View {
        Circle()
            .fill(Color("AppGreen").opacity(0.15))
            .frame(width: 84, height: 84)
            .overlay(
                Text(String((profileVM.username.isEmpty ? profileVM.email : profileVM.username).prefix(1)).uppercased())
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color("AppGreen"))
            )
    }

    private var proCard: some View {
        Button { navigateToPro = true } label: {
            HStack(spacing: 14) {
                Image(systemName: isVip ? "crown.fill" : "crown")
                    .font(.system(size: 22))
                    .foregroundColor(isVip ? Color(hex: "#FBBF24") : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isVip ? "ScanFit Pro" : "Basic Plan")
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundColor(isVip ? Color(hex: "#FBBF24") : .primary)
                    Text(isVip ? "Unlimited scans & all features" : "Tap to upgrade to Pro")
                        .font(.caption).foregroundColor(Color("AppGreen"))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(isVip
                ? Color(hex: "#0F172A")
                : Color(.systemGray6))
            .cornerRadius(14)
        }
    }

    private func uploadPhoto(item: PhotosPickerItem?) async {
        guard let item = item else { return }
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            let resp = try await BackendUserService.shared.changeProfilePicture(
                imageData: data,
                filename: "profile_\(Date().timeIntervalSince1970).jpg"
            )
            if resp.success == true {
                // Reload user data to update photo URL
                await profileVM.loadAll()
            } else {
                photoUploadError = resp.message ?? "Failed to upload photo"
            }
        } catch {
            photoUploadError = error.localizedDescription
        }
    }
    
    private var healthConditionsSection: some View {
        Group {
            if !activeTags.isEmpty {
                sectionCard(title: "Health Conditions") {
                    FlowLayout(spacing: 8) {
                        ForEach(activeTags, id: \.self) { tag in
                            tagView(tag, color: Color("AppGreen"))
                        }
                    }
                }
            }
        }
    }
    
    private var dietSection: some View {
        Group {
            if !activeDiets.isEmpty {
                sectionCard(title: "Diet Preferences") {
                    FlowLayout(spacing: 8) {
                        ForEach(activeDiets, id: \.self) { tag in
                            tagView(tag, color: .blue)
                        }
                    }
                }
            }
        }
    }
    private func tagView(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(20)
    }
    
    private var refreshButton: some View {
        Button {
            Task { await profileVM.refreshTodayCalories() }
        } label: {
            Label("Refresh Today's Calories", systemImage: "arrow.clockwise")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("AppGreen").opacity(0.1))
                .foregroundColor(Color("AppGreen"))
                .cornerRadius(14)
        }
    }
    
    private var signOutButton: some View {
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
}
