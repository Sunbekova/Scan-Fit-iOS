import Foundation
import Combine
import SwiftUI

@MainActor
final class TrackerViewModel: ObservableObject {
    @Published var totalCalories: Int = 0
    @Published var totalProteins: Double = 0
    @Published var totalFat: Double = 0
    @Published var totalCarbs: Double = 0
    @Published var waterGlasses: Int = 0
    @Published var selectedDate: Date = Date()

    let calorieLimit = 2150
    let proteinLimit = 150
    let fatLimit = 70
    let carbLimit = 300
    let maxWaterGlasses = 8

    var caloriesLeft: Int { max(calorieLimit - totalCalories, 0) }
    var proteinsLeft: Double { max(Double(proteinLimit) - totalProteins, 0) }
    var fatLeft: Double { max(Double(fatLimit) - totalFat, 0) }
    var carbsLeft: Double { max(Double(carbLimit) - totalCarbs, 0) }

    var calorieProgress: Double { min(Double(totalCalories) / Double(calorieLimit), 1.0) }
    var proteinProgress: Double { min(totalProteins / Double(proteinLimit), 1.0) }
    var fatProgress: Double { min(totalFat / Double(fatLimit), 1.0) }
    var carbProgress: Double { min(totalCarbs / Double(carbLimit), 1.0) }
    var waterLiters: Double { Double(waterGlasses) * 0.25 }

    // MARK: - Food

    func addFood(_ item: FoodItem) {
        totalCalories += item.calories?.toCleanInt() ?? 0
        totalProteins += item.proteins.toCleanDouble()
        totalFat += item.fat.toCleanDouble()
        totalCarbs += item.carbs.toCleanDouble()
    }

    // MARK: - Water

    func addWater() {
        guard waterGlasses < maxWaterGlasses else { return }
        waterGlasses += 1
    }

    func removeWater() {
        guard waterGlasses > 0 else { return }
        waterGlasses -= 1
    }

    // MARK: - Week Days

    func weekDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    func isSameDay(_ d1: Date, _ d2: Date) -> Bool {
        Calendar.current.isDate(d1, inSameDayAs: d2)
    }
}

// MARK: - String Extensions

private extension String {
    func toCleanDouble() -> Double {
        let cleaned = self.replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." }
        return Double(cleaned) ?? 0
    }

    func toCleanInt() -> Int {
        let cleaned = self.filter { $0.isNumber }
        return Int(cleaned) ?? 0
    }
}

private extension Optional where Wrapped == String {
    func toCleanInt() -> Int {
        guard let self = self else { return 0 }
        let cleaned = self.filter { $0.isNumber }
        return Int(cleaned) ?? 0
    }
}
