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
            NutrientRow(name: "Calories".localized,    consumed: toDouble(d?.calories), goal: toDouble(g?.calories), unit: "kcal".localized, isPremium: false),
            NutrientRow(name: "Carbs".localized, consumed: toDouble(d?.carbs), goal: toDouble(g?.carbs), unit: "g", isPremium: false),
            NutrientRow(name: "Protein".localized, consumed: toDouble(d?.proteins),goal: toDouble(g?.proteins), unit: "g", isPremium: false),
            NutrientRow(name: "Fats".localized, consumed: toDouble(d?.fat), goal: toDouble(g?.fat), unit: "g", isPremium: false),
            NutrientRow(name: "Sodium".localized, consumed: toDouble(d?.sodium), goal: toDouble(g?.sodium), unit: "mg", isPremium: true),
            NutrientRow(name: "Fiber".localized, consumed: toDouble(d?.fiber), goal: toDouble(g?.fiber), unit: "g", isPremium: true),
            NutrientRow(name: "Sugar".localized, consumed: toDouble(d?.sugar), goal: toDouble(g?.sugar), unit: "g", isPremium: true),
            NutrientRow(name: "Cholesterol".localized, consumed: toDouble(d?.cholesterol), goal: toDouble(g?.cholesterol), unit: "mg", isPremium: true),
            NutrientRow(name: "Vitamin A".localized, consumed: d?.vitaminA, goal: g?.vitaminA, unit: "mcg", isPremium: true),
            NutrientRow(name: "Vitamin B12".localized, consumed: d?.vitaminB12, goal: g?.vitaminB12, unit: "mcg", isPremium: true),
            NutrientRow(name: "Vitamin B6".localized, consumed: d?.vitaminB6, goal: g?.vitaminB6, unit: "mg", isPremium: true),
            NutrientRow(name: "Vitamin B9".localized, consumed: d?.vitaminB9, goal: g?.vitaminB9, unit: "mcg", isPremium: true),
            NutrientRow(name: "Vitamin C".localized, consumed: d?.vitaminC, goal: g?.vitaminC, unit: "mg", isPremium: true),
            NutrientRow(name: "Vitamin D".localized, consumed: d?.vitaminD, goal: g?.vitaminD, unit: "mcg", isPremium: true),
            NutrientRow(name: "Vitamin E".localized, consumed: d?.vitaminE, goal: g?.vitaminE, unit: "mg", isPremium: true),
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
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(isLocked ? .secondary : .primary)
                            Spacer()
                            if isLocked {
                                Text("ScanFit Pro")
                                    .font(.caption).fontWeight(.bold)
                                    .foregroundColor(Color(hex: "#2F6BFF"))
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color(hex: "#E8F0FF"))
                                    .cornerRadius(20)
                            } else {
                                Text(formatValue(row))
                                    .font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .opacity(isLocked ? 0.72 : 1.0)

                        if idx < rows.count - 1 {
                            Divider().padding(.leading, 20)
                        }
                    }

                    Button {
                        dismiss()
                        onShowHistory?()
                    } label: {
                        Text("See all history".localized)
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
            .navigationTitle("Daily Impact".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close".localized) { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func toDouble(_ v: Double?) -> Double? { v }
    private func toDouble(_ v: Int?) -> Double? { v.map(Double.init) }

    private func formatValue(_ row: NutrientRow) -> String {
        let consumed = row.consumed.map { String(format: "%.0f", $0) } ?? "–"
        let goal = row.goal.map{ String(format: "%.0f", $0) } ?? "–"
        return "\(consumed) / \(goal) \(row.unit)"
    }
}
