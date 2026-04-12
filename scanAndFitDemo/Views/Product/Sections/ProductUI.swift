//productUI

import SwiftUI

extension ProductDetailView{
    // MARK: - Grade Row

    var gradeRow: some View {
        HStack(spacing: 16) {
            let grade = currentGrade
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(gradeColor(grade)).frame(width: 52, height: 52)
                Text(grade).font(.system(size: 22, weight: .bold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Nutri-Score").font(.caption).foregroundColor(.secondary)
                Text(gradeLabel(grade)).font(.subheadline).fontWeight(.semibold).foregroundColor(gradeColor(grade))
            }
            Spacer()
            if let score = aiResponse?.healthScore {
                VStack(spacing: 2) {
                    Text("\(score)").font(.system(size: 22, weight: .bold))
                        .foregroundColor(gradeColor(currentGrade))
                    Text("Health Score").font(.caption2).foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - tamaq porcia
    var servingSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Serving size").font(.subheadline).fontWeight(.semibold)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(portionValues, id: \.self) { val in
                        let isSelected = abs(val - servingMultiplier) < 0.001
                        Button {
                            servingMultiplier = val
                        } label: {
                            Text(formatAmount(val))
                                .font(.caption).fontWeight(isSelected ? .bold : .regular)
                                .frame(width: 44, height: 44)
                                .background(isSelected ? Color(hex: "#EEEBDD") : Color(.systemBackground))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    // MARK: - Macros

    var macroSection: some View {
        HStack(spacing: 16) {
            MacroProgressItem(title: "Protein", value: currentProteins, maxValue: 50, color: .green)
            MacroProgressItem(title: "Carbs", value: currentCarbs, maxValue: 75, color: .orange)
            MacroProgressItem(title: "Fat", value: currentFat, maxValue: 30, color: .pink)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    // MARK: - macros

    var nutrientsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Nutritional Info").font(.headline).padding(.bottom, 8)

            if let item = foodItem {
                let nutrientMap: [(String, String)] = [
                    ("Total Fat", scaledVal(item.fat)),
                    ("Protein", scaledVal(item.proteins)),
                    ("Total Carbohydrate", scaledVal(item.carbs)),
                    ("Sugar", scaledVal(item.sugars ?? "0g")),
                    ("Fiber", scaledVal(item.fiber ?? "0g")),
                    ("Sodium", scaledVal(item.sodium ?? "0mg")),
                    ("Cholesterol", scaledVal(item.cholesterol ?? "0mg")),
                    ("Vitamin A", scaledVal(item.vitaminA ?? "0")),
                    ("Vitamin B12", scaledVal(item.vitaminB12 ?? "0")),
                    ("Vitamin C", scaledVal(item.vitaminC ?? "0")),
                    ("Vitamin D", scaledVal(item.vitaminD ?? "0")),
                    ("Vitamin E", scaledVal(item.vitaminE ?? "0")),
                    ("Vitamin B6", scaledVal(item.vitaminB6 ?? "0")),
                    ("Vitamin B9 (Folic acid)", scaledVal(item.vitaminB9 ?? "0")),
                ]
                ForEach(nutrientMap, id: \.0) { name, val in
                    NutrientRow(name: name, value: val)
                    Divider()
                }
            } else if let risks = aiResponse?.risks, !risks.isEmpty {
                ForEach(risks) { risk in
                    NutrientRow(name: "Risk", value: risk.ingredient ?? "Issue")
                    Divider()
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

}
