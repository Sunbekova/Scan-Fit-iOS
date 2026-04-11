import SwiftUI

struct MeasurementsSection: View {
    @ObservedObject var profileVM: UserProfileViewModel

    @State private var showGenderPicker = false
    @State private var showBirthPicker = false
    @State private var heightInput = ""
    @State private var weightInput = ""

    var body: some View {
        VStack(spacing: 16) {
            sectionHeader("Body Measurements", subtitle: "Tap a row to edit")

            measurementsCard

            let isVip = TokenManager.shared.userRole == "vip"

            sectionCard(title: "Health Markers") {
                VStack(spacing: 0) {

                    Toggle("High Blood Pressure", isOn: Binding(
                        get: { profileVM.bloodPressure == 1 },
                        set: {
                            profileVM.bloodPressure = $0 ? 1 : 0
                            Task { await profileVM.saveMeasures() }
                        }
                    ))
                    .disabled(!isVip)
                    .opacity(isVip ? 1 : 0.5)

                    Divider()

                    Toggle("High Cholesterol", isOn: Binding(
                        get: { profileVM.cholesterol == 1 },
                        set: {
                            profileVM.cholesterol = $0 ? 1 : 0
                            Task { await profileVM.saveMeasures() }
                        }
                    ))
                    .disabled(!isVip)
                    .opacity(isVip ? 1 : 0.5)
                }
            }
        }
        .padding(.top, 16)
        .sheet(isPresented: $showGenderPicker) {
            PickerSheet(title: "I am a",
                        options: ["Guy", "Gal", "Prefer not to say"],
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

            measureRow(label: "Gender",
                       value: profileVM.gender.isEmpty ? "Not set" : profileVM.gender) {
                showGenderPicker = true
            }

            Divider().padding(.leading, 16)

            measureRow(label: "Date of Birth",
                       value: profileVM.birthDate.isEmpty ? "Not set" : profileVM.birthDate) {
                showBirthPicker = true
            }

            Divider().padding(.leading, 16)

            EditableMeasureRow(label: "Height",
                               value: "\(profileVM.height)",
                               unit: "cm") { val in
                profileVM.height = Int(val) ?? profileVM.height
                Task { await profileVM.saveMeasures() }
            }

            Divider().padding(.leading, 16)

            EditableMeasureRow(label: "Weight",
                               value: "\(profileVM.weight)",
                               unit: "kg") { val in
                profileVM.weight = Int(val) ?? profileVM.weight
                Task { await profileVM.saveMeasures() }
            }

            Divider().padding(.leading, 16)

            measureRow(label: "BMI",
                       value: profileVM.bmiString,
                       action: nil)
        }
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    private func measureRow(label: String,
                            value: String,
                            action: (() -> Void)?) -> some View {

        Button { action?() } label: {
            HStack {
                Text(label)
                Spacer()
                Text(value)
                if action != nil { Image(systemName: "chevron.right") }
            }
            .padding()
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
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
