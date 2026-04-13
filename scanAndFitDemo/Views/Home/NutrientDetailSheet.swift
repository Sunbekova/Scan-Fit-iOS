import SwiftUI

struct NutrientDetailSheet: View {
    let data: BackendUserCaloriesData?
    let day: String
    var onShowHistory: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    private let isVip = TokenManager.shared.isVip

    private struct NutrientRow: Identifiable {
        let id = UUID()
        let name: String
        let consumed: Double?
        let goal: Double?
        let unit: String
        let isPremium: Bool
    }

    private var rows: [NutrientRow] {
        let d = data?.daily
        let g = data
        return [
            NutrientRow(name: "Calories",    consumed: toDouble(d?.calories), goal: toDouble(g?.calories), unit: "kcal", isPremium: false),
            NutrientRow(name: "Carbs", consumed: toDouble(d?.carbs), goal: toDouble(g?.carbs), unit: "g", isPremium: false),
            NutrientRow(name: "Protein", consumed: toDouble(d?.proteins),goal: toDouble(g?.proteins), unit: "g", isPremium: false),
            NutrientRow(name: "Fats", consumed: toDouble(d?.fat), goal: toDouble(g?.fat), unit: "g", isPremium: false),
            NutrientRow(name: "Sodium", consumed: toDouble(d?.sodium), goal: toDouble(g?.sodium), unit: "mg", isPremium: true),
            NutrientRow(name: "Fiber", consumed: toDouble(d?.fiber), goal: toDouble(g?.fiber), unit: "g", isPremium: true),
            NutrientRow(name: "Sugar", consumed: toDouble(d?.sugar), goal: toDouble(g?.sugar), unit: "g", isPremium: true),
            NutrientRow(name: "Cholesterol", consumed: toDouble(d?.cholesterol), goal: toDouble(g?.cholesterol), unit: "mg", isPremium: true),
            NutrientRow(name: "Vitamin A", consumed: d?.vitaminA, goal: g?.vitaminA, unit: "mcg", isPremium: true),
            NutrientRow(name: "Vitamin B12", consumed: d?.vitaminB12, goal: g?.vitaminB12, unit: "mcg", isPremium: true),
            NutrientRow(name: "Vitamin B6", consumed: d?.vitaminB6, goal: g?.vitaminB6, unit: "mg", isPremium: true),
            NutrientRow(name: "Vitamin B9", consumed: d?.vitaminB9, goal: g?.vitaminB9, unit: "mcg", isPremium: true),
            NutrientRow(name: "Vitamin C", consumed: d?.vitaminC, goal: g?.vitaminC, unit: "mg", isPremium: true),
            NutrientRow(name: "Vitamin D", consumed: d?.vitaminD, goal: g?.vitaminD, unit: "mcg", isPremium: true),
            NutrientRow(name: "Vitamin E", consumed: d?.vitaminE, goal: g?.vitaminE, unit: "mg", isPremium: true),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                        let isLocked = row.isPremium && !isVip
                        HStack {
                            Text(row.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(isLocked ? .secondary : .primary)
                            Spacer()
                            if isLocked {
                                Text("ScanFit Pro")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: "#2F6BFF"))
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color(hex: "#E8F0FF"))
                                    .cornerRadius(20)
                            } else {
                                Text(formatValue(row))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .opacity(isLocked ? 0.72 : 1.0)

                        if idx < rows.count - 1 {
                            Divider().padding(.leading, 20)
                        }
                    }

                    // See all history button
                    Button {
                        dismiss()
                        onShowHistory?()
                    } label: {
                        Text("See all history")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color(hex: "#111827"))
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Nutrients")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func formatValue(_ row: NutrientRow) -> String {
        let c = row.consumed ?? 0
        let g = row.goal ?? 0
        return "\(formatAmt(c)) / \(formatAmt(g)) \(row.unit)"
    }

    private func formatAmt(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }
    private func toDouble(_ value: Int?) -> Double? {
        value.map { Double($0) }
    }
}
