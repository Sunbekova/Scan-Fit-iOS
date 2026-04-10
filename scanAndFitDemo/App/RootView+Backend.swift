import SwiftUI

struct RootViewBackend: View {
    @EnvironmentObject var authVM: BackendAuthViewModel

    var body: some View {
        switch authVM.state {
        case .loading:
            SplashView()

        case .unauthenticated:
            LoginView()
                .environmentObject(authVM)

        case .profileIncomplete:
            ProfileSetupBackendView()
                .environmentObject(authVM)

        case .authenticated:
            MainTabView()
                .environmentObject(authVM)
        }
    }
}

struct ProfileSetupBackendView: View {
    @EnvironmentObject var authVM: BackendAuthViewModel
    @StateObject private var profileVM = UserProfileViewModel()

    var body: some View {
        NavigationStack {
            ProfileSetupContent(profileVM: profileVM, authVM: authVM)
                .task { await profileVM.loadAll() }
        }
    }
}

private struct ProfileSetupContent: View {
    @ObservedObject var profileVM: UserProfileViewModel
    @ObservedObject var authVM: BackendAuthViewModel

    @State private var step = 0
    @State private var age = ""
    @State private var gender = "Male"
    @State private var height = 170.0
    @State private var weight = 70.0

    var body: some View {
        VStack {
            if step == 0 {
                measureStep
            } else {
                dietStep
            }
        }
        .navigationTitle(step == 0 ? "Your Measurements" : "Health Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var measureStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Tell us about yourself")
                    .font(.title2.bold())
                    .padding(.top)

                Group {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Age").font(.caption).foregroundColor(.secondary)
                        TextField("Your age", text: $age)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Gender").font(.caption).foregroundColor(.secondary)
                        Picker("Gender", selection: $gender) {
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                            Text("Other").tag("Other")
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Height: \(Int(height)) cm").font(.caption).foregroundColor(.secondary)
                        Slider(value: $height, in: 140...220, step: 1)
                            .accentColor(.green)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Weight: \(Int(weight)) kg").font(.caption).foregroundColor(.secondary)
                        Slider(value: $weight, in: 40...150, step: 1)
                            .accentColor(.green)
                    }
                }
                .padding(.horizontal)

                if let error = profileVM.errorMessage {
                    Text(error).foregroundColor(.red).font(.caption)
                }

                Button {
                    Task {
                        profileVM.age = age
                        profileVM.gender = gender
                        profileVM.height = Int(height)
                        profileVM.weight = Int(weight)
                        await profileVM.saveMeasures()
                        step = 1
                    }
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(14)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
    }

    private var dietStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your Health Profile")
                    .font(.title2.bold())
                    .padding([.top, .horizontal])

                if !profileVM.dietTypes.isEmpty {
                    sectionHeader("Diet Type")
                    ForEach(profileVM.dietTypes) { item in
                        toggleRow(name: item.name, isActive: item.isActive) {
                            Task { await profileVM.toggleDietType(item) }
                        }
                    }
                }

                if !profileVM.healthConditions.isEmpty {
                    sectionHeader("Health Conditions")
                    ForEach(profileVM.healthConditions) { item in
                        toggleRow(name: item.name, isActive: item.isActive) {
                            Task { await profileVM.toggleHealthCondition(item) }
                        }
                    }
                }

                if profileVM.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                }

                Button {
                    authVM.markProfileCompleted()
                } label: {
                    Text("Finish Setup")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(14)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal)
            .padding(.top, 8)
    }

    private func toggleRow(name: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Text(name)
                .font(.body)
            Spacer()
            Toggle("", isOn: .init(get: { isActive }, set: { _ in action() }))
                .tint(.green)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
