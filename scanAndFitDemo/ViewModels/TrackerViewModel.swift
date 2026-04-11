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

    @Published var calorieLimit: Int = 2150
    @Published var proteinLimit: Double = 150
    @Published var fatLimit: Double = 70
    @Published var carbLimit: Double = 300
    @Published var waterGoalMl: Int = 1750

    @Published var selectedDate: Date = Date()
    @Published var isLoading: Bool = false

    let maxWaterGlasses = 7
    let waterGlassMl = 250

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    var caloriesLeft: Int { max(calorieLimit - totalCalories, 0) }
    var proteinsLeft: Double { max(proteinLimit - totalProteins, 0) }
    var fatLeft: Double { max(fatLimit - totalFat, 0) }
    var carbsLeft: Double { max(carbLimit - totalCarbs, 0) }

    var calorieProgress: Double { calorieLimit > 0 ? min(Double(totalCalories) / Double(calorieLimit), 1.0) : 0 }
    var proteinProgress: Double { proteinLimit > 0 ? min(totalProteins / proteinLimit, 1.0) : 0 }
    var fatProgress: Double { fatLimit > 0 ? min(totalFat / fatLimit, 1.0) : 0 }
    var carbProgress: Double { carbLimit > 0 ? min(totalCarbs / carbLimit, 1.0) : 0 }

    var waterLiters: Double { Double(waterGlasses * waterGlassMl) / 1000.0 }
    var waterGoalLiters: Double { Double(waterGoalMl) / 1000.0 }
    var waterProgress: Double { waterGoalMl > 0 ? min(Double(waterGlasses * waterGlassMl) / Double(waterGoalMl), 1.0) : 0 }

    func loadForDate(_ date: Date) {
        let isToday = isSameDay(date, Date())
        let dayStr = dateFormatter.string(from: date)
        Task {
            await fetchCalories(isToday: isToday, day: dayStr)
            await fetchWater(isToday: isToday, day: dayStr)
        }
    }

    private func fetchCalories(isToday: Bool, day: String) async {
        do {
            let resp = isToday
                ? try await BackendUserService.shared.getTodayCalories()
                : try await BackendUserService.shared.getCaloriesByDay(day: day)
            if resp.success, let data = resp.data {
                applyCaloriesData(data)
            }
        } catch {
            // silently fail – keep last values
        }
    }

    private func fetchWater(isToday: Bool, day: String) async {
        do {
            let resp = isToday
                ? try await BackendUserService.shared.getTodayWater()
                : try await BackendUserService.shared.getWaterByDay(day: day)
            if resp.success, let data = resp.data {
                applyWaterData(data)
            }
        } catch {}
    }

    func applyCaloriesData(_ data: BackendUserCaloriesData) {
        calorieLimit = data.calories ?? 2150
        proteinLimit = data.proteins ?? 150
        fatLimit = data.fat ?? 70
        carbLimit = data.carbs ?? 300
        totalCalories = data.daily?.calories ?? 0
        totalProteins = data.daily?.proteins ?? 0
        totalFat = data.daily?.fat ?? 0
        totalCarbs = data.daily?.carbs ?? 0
    }

    func applyWaterData(_ data: BackendUserWaterData) {
        let consumedMl = data.daily?.water ?? data.water ?? 0
        let goalMl = data.daily?.goal ?? 1750
        waterGlasses = consumedMl / waterGlassMl
        waterGoalMl = goalMl
    }


    func addWater() {
        guard waterGlasses < maxWaterGlasses else { return }
        let newCount = waterGlasses + 1
        waterGlasses = newCount
        syncWater(count: newCount)
    }

    func removeWater() {
        guard waterGlasses > 0 else { return }
        let newCount = waterGlasses - 1
        waterGlasses = newCount
        syncWater(count: newCount)
    }

    private func syncWater(count: Int) {
        let day = dateFormatter.string(from: selectedDate)
        let ml = count * waterGlassMl
        Task {
            do {
                let resp = try await BackendUserService.shared.updateWater(day: day, water: ml)
                if resp.success, let data = resp.data {
                    applyWaterData(data)
                }
            } catch {}
        }
    }


    func addFood(_ item: FoodItem) {
        totalCalories += item.calories?.toCleanInt() ?? 0
        totalProteins += item.proteins.toCleanDouble()
        totalFat += item.fat.toCleanDouble()
        totalCarbs += item.carbs.toCleanDouble()
    }

    func weekDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    func isSameDay(_ d1: Date, _ d2: Date) -> Bool {
        Calendar.current.isDate(d1, inSameDayAs: d2)
    }

    var selectedDayString: String { dateFormatter.string(from: selectedDate) }
}

extension String {
    func toCleanDouble() -> Double {
        let cleaned = self.replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." }
        return Double(cleaned) ?? 0
    }

    func toCleanInt() -> Int {
        let cleaned = self.filter { $0.isNumber }
        return Int(cleaned) ?? 0
    }

    func toScaledDouble(multiplier: Double) -> Double {
        return toCleanDouble() * multiplier
    }
}

extension Optional where Wrapped == String {
    func toCleanInt() -> Int {
        guard let self = self else { return 0 }
        return self.toCleanInt()
    }
    func toCleanDouble() -> Double {
        guard let self = self else { return 0 }
        return self.toCleanDouble()
    }
}
