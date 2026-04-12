import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject private var authVM: BackendAuthViewModel
    @StateObject private var profileVM = UserProfileViewModel()
    
    @State private var heightCm = ""
    @State private var weightKg = ""
    @State private var birthdate = Date()
    @State private var gender: Gender = .preferNotToSay
    @State private var showDatePicker = false
    @State private var goToDietSelection = false
    
    enum Gender: String, CaseIterable {
        case male = "Guy"
        case female = "Gal"
        case preferNotToSay = "Prefer not to say"
        
        var label: String {
            switch self {
            case .male: return "Male"
            case .female: return "Female"
            case .preferNotToSay: return "Other"
            }
        }
        
        var backendValue: String {
            switch self {
            case .male: return "Male"
            case .female: return "Female"
            case .preferNotToSay: return "Other"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 6) {
                        Text("Tell us about yourself")
                            .font(.system(size: 26, weight: .bold))
                        Text("We'll personalize your experience")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    .padding(.top, 24)
                    
                    // Gender
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Gender", systemImage: "person.fill")
                            .font(.subheadline).fontWeight(.semibold)
                        HStack(spacing: 12) {
                            ForEach(Gender.allCases, id: \.self) { g in
                                Button(g.label) { gender = g }
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(gender == g ? Color("AppGreen") : Color(.systemGray6))
                                    .foregroundColor(gender == g ? .white : .primary)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    
                    // Height
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Height (cm)", systemImage: "ruler")
                            .font(.subheadline).fontWeight(.semibold)
                        SFTextField(placeholder: "e.g. 175", text: $heightCm, icon: "ruler")
                            .keyboardType(.numberPad)
                    }
                    
                    // Weight
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Weight (kg)", systemImage: "scalemass")
                            .font(.subheadline).fontWeight(.semibold)
                        SFTextField(placeholder: "e.g. 70", text: $weightKg, icon: "scalemass")
                            .keyboardType(.numberPad)
                    }
                    
                    // Birthdate
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Date of Birth", systemImage: "calendar")
                            .font(.subheadline).fontWeight(.semibold)
                        Button {
                            showDatePicker.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "calendar").foregroundColor(.secondary)
                                Text(birthdate.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(showDatePicker ? 180 : 0))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        if showDatePicker {
                            DatePicker("", selection: $birthdate, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                        }
                    }
                    
                    if let error = profileVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    SFPrimaryButton(title: "Continue", isLoading: profileVM.isLoading) {
                        Task { await saveAndContinue() }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationDestination(isPresented: $goToDietSelection) {
                DietSelectionView()
                    .environmentObject(authVM)
                    .environmentObject(profileVM)
            }
        }
        .onAppear {
            Task {
                await profileVM.loadAll()
                if profileVM.hasMeasure {
                    heightCm = String(profileVM.height)
                    weightKg = String(profileVM.weight)
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    
                    profileVM.birthDate = formatter.string(from: birthdate)
                    if let date = formatter.date(from: profileVM.birthDate) {
                        birthdate = date
                    }
                    
                    if let matchedGender = Gender.allCases.first(where: { $0.backendValue == profileVM.gender }) {
                        gender = matchedGender
                    }
                }
            }
        }
    }
    
    private func saveAndContinue() async {
        guard !heightCm.isEmpty, !weightKg.isEmpty else {
            profileVM.errorMessage = "Please enter your height and weight"
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let ageYears = Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year ?? 0
        
        guard ageYears > 0 else {
            profileVM.errorMessage = "Invalid birth date"
            return
        }
        
        profileVM.height = Int(heightCm) ?? 170
        profileVM.weight = Int(weightKg) ?? 70
        profileVM.gender = gender.backendValue
        profileVM.birthDate = formatter.string(from: birthdate)
        profileVM.age = String(ageYears)
        
        await profileVM.saveMeasures()
        
        if profileVM.errorMessage == nil {
            goToDietSelection = true
        }
    }
}
