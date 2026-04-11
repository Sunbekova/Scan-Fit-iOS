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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
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
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        switch selectedTab {
                        case .account: accountSection
                        case .measurements: measurementsSection
                        case .dietary: dietarySection
                        case .diseases: diseasesSection
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
                Button { dismiss() } label: {Image(systemName: "chevron.left").foregroundColor(Color("AppGreen"))}
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await profileVM.refreshTodayCalories() }
                } label: {Image(systemName: "arrow.clockwise").foregroundColor(Color("AppGreen"))}
            }
        }
        .alert("Error", isPresented: Binding(
            get: { profileVM.errorMessage != nil },
            set: { if !$0 { profileVM.errorMessage = nil } }
        )) {Button("OK", role: .cancel) { profileVM.errorMessage = nil }} message: {Text(profileVM.errorMessage ?? "")}
        .task { await profileVM.loadAll() }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color("AppGreen").opacity(0.15))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(String((profileVM.username.isEmpty ? profileVM.email : profileVM.username).prefix(1)).uppercased())
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color("AppGreen"))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(profileVM.username.isEmpty ? "User" : profileVM.username)
                    .font(.title3).fontWeight(.bold)
                Text(profileVM.email)
                    .font(.subheadline).foregroundColor(.secondary)
                let roleText = TokenManager.shared.userRole == "vip" ? "ScanFit Pro" : "Basic"
                Text(roleText)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(roleText == "ScanFit Pro" ? .blue : .secondary)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background((roleText == "ScanFit Pro" ? Color.blue : Color.gray).opacity(0.1))
                    .cornerRadius(10)
            }
            Spacer()
        }
    }

    // MARK: - account Tab

    private var accountSection: some View {
        VStack(spacing: 20) {
            // Stats bar
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

            //acticve health
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

            //active diet
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

            Button(role: .destructive) { authVM.signOut() } label: {
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

    // MARK: - measurements

    @State private var showGenderPicker = false
    @State private var showBirthPicker = false
    @State private var heightInput = ""
    @State private var weightInput = ""

    private var measurementsSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Body Measurements", subtitle: "Tap a row to edit")

            measurementsCard

            let isVip = TokenManager.shared.userRole == "vip"
            sectionCard(title: "Health Markers") {
                VStack(spacing: 0) {
                    Toggle("High Blood Pressure", isOn: Binding(
                        get: { profileVM.bloodPressure == 1 },
                        set: { profileVM.bloodPressure = $0 ? 1 : 0; Task { await profileVM.saveMeasures() } }
                    ))
                    .disabled(!isVip)
                    .opacity(isVip ? 1 : 0.5)
                    .padding(.vertical, 4)

                    Divider()

                    Toggle("High Cholesterol", isOn: Binding(
                        get: { profileVM.cholesterol == 1 },
                        set: { profileVM.cholesterol = $0 ? 1 : 0; Task { await profileVM.saveMeasures() } }
                    ))
                    .disabled(!isVip)
                    .opacity(isVip ? 1 : 0.5)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.top, 16)
        .sheet(isPresented: $showGenderPicker) {
            PickerSheet(title: "I am a", options: ["Guy", "Gal", "Prefer not to say"],
                        selected: profileVM.gender) { val in
                profileVM.gender = val
                Task { await profileVM.saveMeasures() }
            }
        }
        .sheet(isPresented: $showBirthPicker) {
            BirthDatePickerSheet(birthDate: profileVM.birthDate) { date in
                profileVM.birthDate = date
                Task { await profileVM.saveMeasures(customBirthDate: date) }
            }
        }
    }

    private var measurementsCard: some View {
        VStack(spacing: 0) {
            measureRow(label: "Gender", value: profileVM.gender.isEmpty ? "Not set" : profileVM.gender) {showGenderPicker = true}
            Divider().padding(.leading, 16)
            measureRow(label: "Date of Birth", value: profileVM.birthDate.isEmpty ? "Not set" : profileVM.birthDate) {showBirthPicker = true}
            Divider().padding(.leading, 16)
            EditableMeasureRow(label: "Height", value: "\(profileVM.height)", unit: "cm") { val in
                profileVM.height = Int(val) ?? profileVM.height
                Task { await profileVM.saveMeasures() }
            }
            Divider().padding(.leading, 16)
            EditableMeasureRow(label: "Weight", value: "\(profileVM.weight)", unit: "kg") { val in
                profileVM.weight = Int(val) ?? profileVM.weight
                Task { await profileVM.saveMeasures() }
            }
            Divider().padding(.leading, 16)
            measureRow(label: "BMI", value: profileVM.bmiString, action: nil)
        }
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    private func measureRow(label: String, value: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            HStack {
                Text(label).font(.body).foregroundColor(.primary)
                Spacer()
                Text(value).font(.subheadline).foregroundColor(.secondary)
                if action != nil {Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)}
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    // MARK: - dietary

    private var dietarySection: some View {
        VStack(spacing: 20) {
            sectionHeader("Weight Management", subtitle: "Goal, target date, target weight")
            weightManagementCard

            //diet by category
            let grouped = Dictionary(grouping: profileVM.dietTypes) { $0.category ?? "My Diet" }
            ForEach(grouped.keys.sorted(), id: \.self) { category in
                sectionHeader(category, subtitle: "Personalized picks")
                VStack(spacing: 8) {
                    ForEach(grouped[category] ?? []) { item in
                        dietToggleRow(item: item, type: .diet)
                    }
                }
            }

            //dietary Preferences
            if !profileVM.dietaryPrefs.isEmpty {
                sectionHeader("Dietary Preferences", subtitle: "Personalized picks")
                VStack(spacing: 8) {
                    ForEach(profileVM.dietaryPrefs) { item in
                        dietToggleRow(item: item, type: .preference)
                    }
                }
            }

            //gealth conditions
            if !profileVM.healthConditions.isEmpty {
                sectionHeader("Health Condition", subtitle: "Personalized picks")
                VStack(spacing: 8) {
                    ForEach(profileVM.healthConditions) { item in
                        dietToggleRow(item: item, type: .condition)
                    }
                }
            }
        }
        .padding(.top, 16)
    }

    enum DietItemType { case diet, preference, condition }

    private func dietToggleRow(item: BackendDietType, type: DietItemType) -> some View {
        let isVip = TokenManager.shared.userRole == "vip"
        let canToggle = type == .diet || isVip

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.body).fontWeight(.semibold)
                Text(type == .diet ? "Diet" : type == .preference ? "Preference" : "Condition")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { item.isActive },
                set: { _ in
                    if canToggle {
                        Task {
                            switch type {
                            case .diet: await profileVM.toggleDietType(item)
                            case .preference: await profileVM.toggleDietaryPreference(item)
                            case .condition: await profileVM.toggleHealthCondition(item)
                            }
                        }
                    }
                }
            ))
            .disabled(!canToggle)
            .opacity(canToggle ? 1 : 0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    @State private var showGoalPicker = false
    @State private var showTargetDatePicker = false
    @State private var showTargetWeightInput = false

    private var weightManagementCard: some View {
        VStack(spacing: 0) {
            weightManagementRow(label: "Goal",
                value: profileVM.weightGoal.isEmpty ? "Not set" : profileVM.weightGoal.capitalized) {
                showGoalPicker = true
            }
            Divider().padding(.leading, 16)
            weightManagementRow(label: "Target date",
                value: profileVM.targetDateDisplay) {
                showTargetDatePicker = true
            }
            Divider().padding(.leading, 16)
            weightManagementRow(label: "Target weight",
                value: profileVM.targetWeight > 0 ? "\(profileVM.targetWeight) kg" : "Not set") {
                showTargetWeightInput = true
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .sheet(isPresented: $showGoalPicker) {
            PickerSheet(title: "Goal", options: ["Lose", "Maintain", "Gain"], selected: profileVM.weightGoal.capitalized) { val in
                profileVM.weightGoal = val.lowercased()
                Task { await profileVM.saveWeightManagement() }
            }
        }
        .sheet(isPresented: $showTargetDatePicker) {
            BirthDatePickerSheet(birthDate: profileVM.targetDate) { date in
                profileVM.targetDate = date
                Task { await profileVM.saveWeightManagement() }
            }
        }
        .sheet(isPresented: $showTargetWeightInput) {
            NumberInputSheet(title: "Target weight", unit: "kg", current: profileVM.targetWeight) { val in
                profileVM.targetWeight = val
                Task { await profileVM.saveWeightManagement() }
            }
        }
    }

    private func weightManagementRow(label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label).font(.body).fontWeight(.semibold).foregroundColor(.primary)
                Spacer()
                Text(value).font(.subheadline).foregroundColor(.secondary)
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Disease

    @State private var selectedDiseaseForEdit: BackendDisease? = nil

    private var diseasesSection: some View {
        VStack(spacing: 16) {
            let isVip = TokenManager.shared.userRole == "vip"
            let activeCount = profileVM.diseases.filter(\.isActive).count
            let subtitle = isVip ? "Tap a card to set level" : "Selected \(activeCount) of 3"
            sectionHeader("Diseases", subtitle: subtitle)

            ForEach(profileVM.diseases) { disease in
                diseaseCard(disease: disease)
                    .onTapGesture { selectedDiseaseForEdit = disease }
            }
        }
        .padding(.top, 16)
        .sheet(item: $selectedDiseaseForEdit) { disease in
            DiseaseLevelSheet(
                disease: disease,
                levels: profileVM.diseaseLevels
            ) { levelId, isActive in
                Task { await profileVM.toggleDisease(disease, levelId: levelId, isActive: isActive) }
                selectedDiseaseForEdit = nil
            }
        }
    }

    private func diseaseCard(disease: BackendDisease) -> some View {
        let isSelected = disease.isActive
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(disease.name).font(.body).fontWeight(.bold)
                    .foregroundColor(isSelected ? Color(hex: "#163E9F") : .primary)
                Spacer()
                Text(isSelected ? (disease.diseaseLevel?.name ?? "Selected") : "Not selected")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .blue)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .cornerRadius(50)
            }
            if let desc = disease.description {Text(desc).font(.caption).foregroundColor(.secondary).lineLimit(2)}
            HStack {
                Text(disease.code.map { "Code \($0)" } ?? "Condition").font(.caption).foregroundColor(.secondary)
                Spacer()
                Text(isSelected ? "Active" : "Inactive").font(.caption).foregroundColor(.secondary)
                Text(isSelected ? "Selected" : (TokenManager.shared.userRole == "vip" ? "Manage" : "Choose"))
                    .font(.caption).fontWeight(.bold).foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(isSelected ? Color(hex: "#EAF2FF") : Color(.systemGray6))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(isSelected ? Color(hex: "#2F6BFF") : Color(.systemGray4), lineWidth: isSelected ? 2 : 1))
    }

    // MARK: - Helpers

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title3).fontWeight(.bold)
            Text(subtitle).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Supporting Sheets

struct PickerSheet: View {
    let title: String
    let options: [String]
    let selected: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selection: String

    init(title: String, options: [String], selected: String, onSelect: @escaping (String) -> Void) {
        self.title = title; self.options = options; self.selected = selected; self.onSelect = onSelect
        _selection = State(initialValue: selected.isEmpty ? (options.first ?? "") : selected)
    }

    var body: some View {
        NavigationStack {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.wheel)
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onSelect(selection); dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct BirthDatePickerSheet: View {
    let birthDate: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    private let formatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    var body: some View {
        NavigationStack {
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { onSelect(formatter.string(from: date)); dismiss() }
                    }
                }
        }
        .onAppear {
            if let d = formatter.date(from: birthDate) { date = d }
        }
        .presentationDetents([.medium])
    }
}

struct NumberInputSheet: View {
    let title: String
    let unit: String
    let current: Int
    let onSave: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var input = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(title).font(.title2).fontWeight(.bold)
                HStack {
                    TextField("Enter value", text: $input)
                        .keyboardType(.numberPad)
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                    Text(unit).font(.title3).foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 40)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let val = Int(input), val > 0 { onSave(val) }
                        dismiss()
                    }
                }
            }
        }
        .onAppear { input = "\(current)" }
        .presentationDetents([.medium])
    }
}

struct DiseaseLevelSheet: View {
    let disease: BackendDisease
    let levels: [BackendDiseaseLevel]
    let onSave: (Int, Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isActive: Bool
    @State private var selectedLevelIdx: Int = 0

    init(disease: BackendDisease, levels: [BackendDiseaseLevel], onSave: @escaping (Int, Bool) -> Void) {
        self.disease = disease; self.levels = levels; self.onSave = onSave
        _isActive = State(initialValue: disease.isActive)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(disease.name).font(.title2).fontWeight(.bold)
                    if let code = disease.code { Text("Code \(code)").font(.caption).foregroundColor(.secondary) }
                    if let desc = disease.description { Text(desc).font(.subheadline).foregroundColor(.secondary) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Toggle("This condition is active", isOn: $isActive)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                if !levels.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Severity Level").font(.headline)
                        Picker("Level", selection: $selectedLevelIdx) {
                            ForEach(Array(levels.enumerated()), id: \.offset) { idx, lvl in
                                Text(lvl.name).tag(idx)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                }
            }
            .padding()
            .navigationTitle("Disease Level")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let levelId = levels.indices.contains(selectedLevelIdx) ? levels[selectedLevelIdx].id : (levels.first?.id ?? 1)
                        onSave(levelId, isActive)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let lvl = disease.diseaseLevel,
               let idx = levels.firstIndex(where: { $0.id == lvl.id }) {
                selectedLevelIdx = idx
            }
        }
        .presentationDetents([.large])
    }
}

struct EditableMeasureRow: View {
    let label: String
    let value: String
    let unit: String
    let onSave: (String) -> Void
    @State private var showSheet = false

    var body: some View {
        Button { showSheet = true } label: {
            HStack {
                Text(label).font(.body).foregroundColor(.primary)
                Spacer()
                Text("\(value) \(unit)").font(.subheadline).foregroundColor(.secondary)
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            InlineNumberInputSheet(label: label, unit: unit, current: value) { newVal in
                onSave(newVal)
            }
        }
    }
}

struct InlineNumberInputSheet: View {
    let label: String
    let unit: String
    let current: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var input = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("My \(label.lowercased()) is").font(.title2).fontWeight(.bold)
                HStack {
                    TextField("Value", text: $input)
                        .keyboardType(.numberPad)
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                    Text(unit).font(.title3).foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 40)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { if !input.isEmpty { onSave(input) }; dismiss() }
                }
            }
        }
        .onAppear { input = current }
        .presentationDetents([.medium])
    }
}

// MARK: - StatItem, FlowLayout (keep original names)

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
        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            if x + sz.width > width, x > 0 { x = 0; y += maxHeight + spacing; maxHeight = 0 }
            maxHeight = max(maxHeight, sz.height)
            x += sz.width + spacing
        }
        return CGSize(width: width, height: y + maxHeight)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, maxHeight: CGFloat = 0
        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += maxHeight + spacing; maxHeight = 0 }
            sub.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            maxHeight = max(maxHeight, sz.height)
            x += sz.width + spacing
        }
    }
}
