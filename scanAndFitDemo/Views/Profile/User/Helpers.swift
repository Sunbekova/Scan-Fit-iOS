import SwiftUI

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
