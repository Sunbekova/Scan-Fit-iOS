import SwiftUI

struct DiseasesSection: View {
    @ObservedObject var profileVM: UserProfileViewModel
    @State private var selectedDiseaseForEdit: BackendDisease? = nil

    var body: some View {
        VStack(spacing: 16) {
            let isVip = TokenManager.shared.userRole == "vip"
            let activeCount = profileVM.diseases.filter(\.isActive).count
            let subtitle = isVip
                ? "Tap a card to set level".localized
                : String(format: "Selected %d of 3".localized, activeCount)

            sectionHeader("Diseases".localized, subtitle: subtitle)

            ForEach(profileVM.diseases) { disease in
                diseaseCard(disease: disease)
                    .onTapGesture {
                        if disease.isActive {
                            selectedDiseaseForEdit = disease
                        } else {
                            Task {
                                await profileVM.toggleDisease(disease,
                                                              levelId: profileVM.diseaseLevels.first?.id ?? 1,
                                                              isActive: true)
                            }
                        }
                    }
            }
        }
        .padding(.top, 16)
        .sheet(item: $selectedDiseaseForEdit) { disease in
            DiseaseLevelSheet(
                disease: disease,
                levels: profileVM.diseaseLevels
            ) { levelId, isActive in
                Task {
                    await profileVM.toggleDisease(disease, levelId: levelId, isActive: isActive)
                    selectedDiseaseForEdit = nil
                }
            }
        }
    }

    private func diseaseCard(disease: BackendDisease) -> some View {
        let isSelected = disease.isActive

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(disease.displayName).font(.body).fontWeight(.bold)
                    .foregroundColor(isSelected ? Color(hex: "#163E9F") : .primary)

                Spacer()

                Text(isSelected
                     ? (disease.diseaseLevel?.name ?? "Selected".localized)
                     : "Not selected".localized)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .blue)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .cornerRadius(50)
            }

            if let desc = disease.description {
                Text(desc)
                    .font(.caption).foregroundColor(.secondary).lineLimit(2)
            }

            HStack {
                Text(disease.code.map { String(format: "Code %@".localized, $0) } ?? "Condition".localized)
                    .font(.caption).foregroundColor(.secondary)

                Spacer()

                Text(isSelected ? "Active".localized : "Inactive".localized)
                    .font(.caption).foregroundColor(.secondary)

                Text(isSelected
                     ? "Selected".localized
                     : (TokenManager.shared.userRole == "vip" ? "Manage".localized : "Choose".localized))
                    .font(.caption).fontWeight(.bold).foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(isSelected ? Color(hex: "#EAF2FF") : Color(.systemGray6))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color(hex: "#2F6BFF") : Color(.systemGray4),
                        lineWidth: isSelected ? 2 : 1)
        )
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
                    Text(disease.displayName).font(.title2).fontWeight(.bold)
                    if let code = disease.code {
                        Text(String(format: "Code %@".localized, code))
                            .font(.caption).foregroundColor(.secondary)
                    }
                    if let desc = disease.description {
                        Text(desc).font(.subheadline).foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Toggle("This condition is active".localized, isOn: $isActive)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                if !levels.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Severity Level".localized).font(.headline)
                        Picker("Level".localized, selection: $selectedLevelIdx) {
                            ForEach(Array(levels.enumerated()), id: \.offset) { idx, lvl in
                                Text(lvl.name ?? "Unknown Condition".localized).tag(idx)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                }
            }
            .padding()
            .navigationTitle("Disease Level".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        let levelId = levels.indices.contains(selectedLevelIdx)
                            ? levels[selectedLevelIdx].id
                            : (levels.first?.id ?? 1)
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
