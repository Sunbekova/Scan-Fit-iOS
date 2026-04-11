import SwiftUI

struct NutrientDetailSheet: View {
    let data: BackendUserCaloriesData?
    let day: String
    @Environment(\.dismiss) private var dismiss

    private var isVip: Bool { TokenManager.shared.userRole == "vip" }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Basic Nutrients") {
                    nutrientRow("Calories", consumed: data?.daily?.calories.map { Double($0) }, goal: data?.calories.map { Double($0) }, unit: "kcal")
                    nutrientRow("Carbs", consumed: data?.daily?.carbs, goal: data?.carbs, unit: "g")
                    nutrientRow("Protein", consumed: data?.daily?.proteins, goal: data?.proteins, unit: "g")
                    nutrientRow("Fats", consumed: data?.daily?.fat, goal: data?.fat, unit: "g")
                }

                Section("Premium Nutrients") {
                    premiumNutrientRow("Sodium", consumed: data?.daily?.sodium, goal: data?.sodium, unit: "mg")
                    premiumNutrientRow("Fiber", consumed: data?.daily?.fiber, goal: data?.fiber, unit: "g")
                    premiumNutrientRow("Sugar", consumed: data?.daily?.sugar, goal: data?.sugar, unit: "g")
                    premiumNutrientRow("Cholesterol", consumed: data?.daily?.cholesterol, goal: data?.cholesterol, unit: "mg")
                    premiumNutrientRow("Vitamin A", consumed: data?.daily?.vitaminA, goal: data?.vitaminA, unit: "mcg")
                    premiumNutrientRow("Vitamin B12", consumed: data?.daily?.vitaminB12, goal: data?.vitaminB12, unit: "mcg")
                    premiumNutrientRow("Vitamin B6", consumed: data?.daily?.vitaminB6, goal: data?.vitaminB6, unit: "mg")
                    premiumNutrientRow("Vitamin C", consumed: data?.daily?.vitaminC, goal: data?.vitaminC, unit: "mg")
                    premiumNutrientRow("Vitamin D", consumed: data?.daily?.vitaminD, goal: data?.vitaminD, unit: "mcg")
                    premiumNutrientRow("Vitamin E", consumed: data?.daily?.vitaminE, goal: data?.vitaminE, unit: "mg")
                }
            }
            .navigationTitle("Nutrients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func nutrientRow(_ name: String, consumed: Double?, goal: Double?, unit: String) -> some View {
        HStack {
            Text(name).font(.body)
            Spacer()
            Text(formatPair(consumed, goal, unit))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func premiumNutrientRow(_ name: String, consumed: Double?, goal: Double?, unit: String) -> some View {
        HStack {
            Text(name).font(.body).opacity(isVip ? 1 : 0.6)
            Spacer()
            if isVip {
                Text(formatPair(consumed, goal, unit))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("ScanFit Pro")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
            }
        }
    }

    private func formatPair(_ consumed: Double?, _ goal: Double?, _ unit: String) -> String {
        let c = formatAmount(consumed ?? 0)
        let g = formatAmount(goal ?? 0)
        return "\(c) / \(g) \(unit)"
    }

    private func formatAmount(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }
}
