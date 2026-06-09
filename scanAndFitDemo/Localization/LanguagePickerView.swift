import SwiftUI

struct LanguagePickerView: View {
    @ObservedObject private var lm = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(AppLanguage.allCases) { language in
                Button {
                    lm.set(language)
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        Text(language.flag)
                            .font(.system(size: 28))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(language.displayName)
                                .font(.body)
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        if lm.current == language {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("AppGreen"))
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("App Language".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
            }
        }
    }
}

/// Inline row for embedding inside any settings/profile section.
struct LanguageRow: View {
    @ObservedObject private var lm = LanguageManager.shared
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("AppGreen").opacity(0.12))
                        .frame(width: 36, height: 36)
                    Text(lm.current.flag)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Language".localized)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(lm.current.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
        .sheet(isPresented: $showPicker) {
            LanguagePickerView()
                .languageAware()
        }
    }
}
