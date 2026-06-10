import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject private var authVM: BackendAuthViewModel
    @StateObject private var profileVM = UserProfileViewModel()

    @State private var height: Double = 170
    @State private var weight: Double = 70
    @State private var birthdate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var gender: Gender = .male
    @State private var showDatePicker = false
    @State private var goToDietSelection = false
    
    enum Gender: String, CaseIterable {
        case male = "Guy"
        case female = "Gal"
        case preferNotToSay = "Other"

        var label: String {
            switch self {
            case .male: return "Male".localized
            case .female: return "Female".localized
            case .preferNotToSay: return "Other".localized
            }
        }
        var backendValue: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 6) {
                        Text("Tell us about yourself".localized)
                            .font(.system(size: 26, weight: .bold))
                        Text("We'll personalise your experience".localized)
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    .padding(.top, 24)
                    
                    // Gender
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Gender".localized, systemImage: "person.fill")
                            .font(.subheadline).fontWeight(.semibold)
                        HStack(spacing: 12) {
                            ForEach(Gender.allCases, id: \.self) { g in
                                Button(g.label) { gender = g }
                                    .font(.subheadline)
                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                    .background(gender == g ? Color("AppGreen") : Color(.systemGray6))
                                    .foregroundColor(gender == g ? .white : .primary)
                                    .cornerRadius(10)
                            }
                        }
                    }

                    // Height Slider
                    VStack(alignment: .leading, spacing: 10) {
                        Label(String(format: "Height: %d cm".localized, Int(height)), systemImage: "ruler")
                            .font(.subheadline).fontWeight(.semibold)
                        Slider(value: $height, in: 140...220, step: 1)
                            .accentColor(Color("AppGreen"))
                        HStack {
                            Text("140 cm").font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text("220 cm").font(.caption).foregroundColor(.secondary)
                        }
                    }

                    // Weight Slider
                    VStack(alignment: .leading, spacing: 10) {
                        Label(String(format: "Weight: %d kg".localized, Int(weight)), systemImage: "scalemass")
                            .font(.subheadline).fontWeight(.semibold)
                        Slider(value: $weight, in: 30...200, step: 1)
                            .accentColor(Color("AppGreen"))
                        HStack {
                            Text("30 kg").font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text("200 kg").font(.caption).foregroundColor(.secondary)
                        }
                    }

                    // Birthdate
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Date of Birth".localized, systemImage: "calendar")
                            .font(.subheadline).fontWeight(.semibold)
                        Button { showDatePicker.toggle() } label: {
                            HStack {
                                Image(systemName: "calendar").foregroundColor(.secondary)
                                Text(birthdate.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down").foregroundColor(.secondary)
                                    .rotationEffect(.degrees(showDatePicker ? 180 : 0))
                            }
                            .padding().background(Color(.systemGray6)).cornerRadius(12)
                        }
                        if showDatePicker {
                            DatePicker("", selection: $birthdate,
                                       in: Calendar.current.date(byAdding: .year, value: -100, to: Date())!...Calendar.current.date(byAdding: .year, value: -10, to: Date())!,
                                       displayedComponents: .date)
                                .datePickerStyle(.wheel).labelsHidden()
                        }
                    }
                    
                    if let error = profileVM.errorMessage {
                        Text(error).font(.caption).foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    SFPrimaryButton(title: "Continue".localized, isLoading: profileVM.isLoading) {
                        Task { await saveAndContinue() }
                    }
                    .padding(.top, 8)
//                //extrennye sluchay
//                    Button("Force Logout") {
//                        authVM.signOut()
//                    }
//                    .padding()
                }
                .padding(.horizontal, 24).padding(.bottom, 40)
            }
            .navigationDestination(isPresented: $goToDietSelection) {
                DietSelectionView()
                    .environmentObject(authVM)
                    .environmentObject(profileVM)
            }
        }.task { await profileVM.loadAll() }
    }
    
    private func saveAndContinue() async {
        let ageYears = Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year ?? 0
        guard ageYears >= 10 else {
            profileVM.errorMessage = "Invalid birth date".localized; return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        profileVM.height = Int(height)
        profileVM.weight = Int(weight)
        profileVM.gender = gender.backendValue
        profileVM.birthDate = formatter.string(from: birthdate)
        profileVM.age = String(ageYears)
        profileVM.errorMessage = nil
        await profileVM.saveMeasures()
        if profileVM.errorMessage == nil {
            goToDietSelection = true
        }
    }
}
