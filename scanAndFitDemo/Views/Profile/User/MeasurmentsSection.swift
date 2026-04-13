import SwiftUI

struct MeasurementsSection: View {
    @ObservedObject var profileVM: UserProfileViewModel
    @EnvironmentObject var authVM: BackendAuthViewModel

    @State private var showGenderPicker = false
    @State private var showBirthPicker = false
    @State private var bpError: String? = nil
    @State private var cholError: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            sectionHeader("Body Measurements", subtitle: "Tap a row to edit")
            measurementsCard

            let isVip = TokenManager.shared.isVip

            sectionCard(title: "Health Markers") {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("High Blood Pressure", isOn: Binding(
                            get: { profileVM.bloodPressure == 1 },
                            set: { newVal in
                                guard isVip else { return }
                                profileVM.bloodPressure = newVal ? 1 : 0
                                Task { await saveMeasureHandlingErrors() }
                            }
                        ))
                        .disabled(!isVip)
                        .opacity(isVip ? 1 : 0.55)

                        if !isVip {
                            Label("Pro feature", systemImage: "crown.fill")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "#FBBF24"))
                        }
                        if let err = bpError {
                            Text(err).font(.caption2).foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 6)

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("High Cholesterol", isOn: Binding(
                            get: { profileVM.cholesterol == 1 },
                            set: { newVal in
                                guard isVip else { return }
                                profileVM.cholesterol = newVal ? 1 : 0
                                Task { await saveMeasureHandlingErrors() }
                            }
                        ))
                        .disabled(!isVip)
                        .opacity(isVip ? 1 : 0.55)

                        if !isVip {
                            Label("Pro feature", systemImage: "crown.fill")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "#FBBF24"))
                        }
                        if let err = cholError {
                            Text(err).font(.caption2).foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.top, 16)
        .sheet(isPresented: $showGenderPicker) {
            PickerSheet(title: "I am a",
                        options: ["Guy", "Gal", "Prefer not to say"],
                        selected: profileVM.gender) { val in
                profileVM.gender = val
                Task { await saveMeasureHandlingErrors() }
            }
        }
        .sheet(isPresented: $showBirthPicker) {
            BirthDatePickerSheet(birthDate: profileVM.birthDate) { date in
                profileVM.birthDate = date
                Task { await profileVM.saveMeasures(customBirthDate: date) }
            }
        }
    }

    private func saveMeasureHandlingErrors() async {
        do {
            try await profileVM.saveMeasuresThrows()
            bpError   = nil
            cholError = nil
        } catch let err as BackendError {
            switch err {
            case .sessionExpired:
                authVM.handleSessionError(err)
            case .notAuthenticated:
                authVM.handleSessionError(err)
            case .apiError(let msg):
                bpError = msg
            }
        } catch {
            bpError = error.localizedDescription
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
            EditableMeasureRow(label: "Height", value: "\(profileVM.height)", unit: "cm") { val in
                profileVM.height = Int(val) ?? profileVM.height
                Task { await saveMeasureHandlingErrors() }
            }
            Divider().padding(.leading, 16)
            EditableMeasureRow(label: "Weight", value: "\(profileVM.weight)", unit: "kg") { val in
                profileVM.weight = Int(val) ?? profileVM.weight
                Task { await saveMeasureHandlingErrors() }
            }
            Divider().padding(.leading, 16)
            measureRow(label: "BMI", value: profileVM.bmiString, action: nil)
        }
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    private func measureRow(label: String, value: String, action: (() -> Void)?) -> some View {
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
    let label, value, unit: String
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
            InlineNumberInputSheet(label: label, unit: unit, current: value) { onSave($0) }
        }
    }
}
