import SwiftUI

struct SFPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color("AppGreen"))
            .cornerRadius(28)
            .shadow(color: Color("AppGreen").opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(isLoading)
    }
}

// MARK: - Text Field
struct SFTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            if let iconName = icon, !iconName.isEmpty {
                Image(systemName: iconName)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
            }            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .autocapitalization(.none)
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(Color(.systemGray6).opacity(0.6))
        .cornerRadius(12)
    }
}

// MARK: - Secure Field
struct CleanSecureField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        SecureField(placeholder, text: $text)
            .font(.system(size: 16))
            .autocapitalization(.none)
            .textContentType(.newPassword)
            .padding()
            .frame(height: 56)
            .background(Color(.systemGray6).opacity(0.6))
            .cornerRadius(12)
    }
}

// MARK: - Food Row View
struct FoodRowView: View {
    let item: FoodItem
    let showFavorite: Bool
    let onFavoriteToggle: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let urlStr = item.imageURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    if let cal = item.calories {
                        Text(cal)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    if let grade = item.grade {
                        GradeBadgeView(grade: grade)
                    }
                }
            }

            Spacer()

            if showFavorite, let toggle = onFavoriteToggle {
                Button(action: toggle) {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(item.isFavorite ? .red : .gray.opacity(0.5))
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color("AppGreen").opacity(0.1))
            .overlay(
                Image(systemName: "carrot.fill")
                    .foregroundColor(Color("AppGreen").opacity(0.5))
            )
    }
}

// MARK: - Grade Badge
struct GradeBadgeView: View {
    let grade: String

    var color: Color {
        switch grade.uppercased() {
        case "A": return Color.green
        case "B": return Color.green.opacity(0.7)
        case "C": return Color.yellow
        case "D": return Color.orange
        case "E": return Color.red
        default: return .gray
        }
    }

    var body: some View {
        Text(grade.uppercased())
            .font(.system(size: 12, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}

    //product
struct NutrientRow: View {
    let name: String
    let value: String
    var body: some View {
        HStack {
            Text(name).font(.subheadline).foregroundColor(.primary)
            Spacer()
            Text(value).font(.subheadline).foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct MacroProgressItem: View {
    let title: String
    let value: Double
    let maxValue: Double
    let color: Color
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(color.opacity(0.2), lineWidth: 6).frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: min(CGFloat(value / maxValue), 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 60, height: 60)
                Text("\(Int(value))").font(.system(size: 13, weight: .bold))
            }
            Text(title).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Picker Sheet
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done".localized) { onSelect(selection); dismiss() }
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
                .navigationTitle("Select Date".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel".localized) { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done".localized) { onSelect(formatter.string(from: date)); dismiss() }
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
                    TextField("Enter value".localized, text: $input)
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
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
                Text(String(format: "My %@ is".localized, label.lowercased()))
                    .font(.title2).fontWeight(.bold)
                HStack {
                    TextField("Value".localized, text: $input)
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) { if !input.isEmpty { onSave(input) }; dismiss() }
                }
            }
        }
        .onAppear { input = current }
        .presentationDetents([.medium])
    }
}

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
