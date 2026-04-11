import SwiftUI

struct DietarySection: View {
    @ObservedObject var profileVM: UserProfileViewModel

    @State private var showGoalPicker = false
    @State private var showTargetDatePicker = false
    @State private var showTargetWeightInput = false

    var body: some View {
        VStack(spacing: 20) {
            sectionHeader("Weight Management", subtitle: "Goal, target date, target weight")
            weightManagementCard

            let grouped = Dictionary(grouping: profileVM.dietTypes) { $0.category ?? "My Diet" }

            ForEach(grouped.keys.sorted(), id: \.self) { category in
                sectionHeader(category, subtitle: "Personalized picks")

                VStack(spacing: 8) {
                    ForEach(grouped[category] ?? []) { item in
                        dietToggleRow(item: item, type: .diet)
                    }
                }
            }

            if !profileVM.dietaryPrefs.isEmpty {
                sectionHeader("Dietary Preferences", subtitle: "Personalized picks")

                VStack(spacing: 8) {
                    ForEach(profileVM.dietaryPrefs) { item in
                        dietToggleRow(item: item, type: .preference)
                    }
                }
            }

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

    private var weightManagementCard: some View {
        VStack(spacing: 0) {
            weightManagementRow(
                label: "Goal",
                value: profileVM.weightGoal.isEmpty ? "Not set" : profileVM.weightGoal.capitalized
            ) { showGoalPicker = true }

            Divider().padding(.leading, 16)

            weightManagementRow(
                label: "Target date",
                value: profileVM.targetDateDisplay
            ) { showTargetDatePicker = true }

            Divider().padding(.leading, 16)

            weightManagementRow(
                label: "Target weight",
                value: profileVM.targetWeight > 0 ? "\(profileVM.targetWeight) kg" : "Not set"
            ) { showTargetWeightInput = true }
        }
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .sheet(isPresented: $showGoalPicker) {
            PickerSheet(
                title: "Goal",
                options: ["Lose", "Maintain", "Gain"],
                selected: profileVM.weightGoal.capitalized
            ) { val in
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
                Text(label).font(.body).fontWeight(.semibold)
                Spacer()
                Text(value).font(.subheadline).foregroundColor(.secondary)
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}
