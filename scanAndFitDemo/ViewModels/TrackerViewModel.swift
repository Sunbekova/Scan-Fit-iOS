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

    @Published var firstAvailableDate: Date? = nil
    @Published var waterError: String? = nil
    @Published var isWaterUpdating: Bool = false

    let waterGlassMl = 250
    private let defaultWaterGlasses = 8
    var maxWaterGlasses: Int {
        guard waterGoalMl > 0 else { return defaultWaterGlasses }
        return max(Int(ceil(Double(waterGoalMl) / Double(waterGlassMl))), 1)
    }

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

    var calorieProgress: Double { calorieLimit > 0 ? min(Double(totalCalories) / Double(calorieLimit), 1) : 0 }
    var proteinProgress: Double { proteinLimit > 0 ? min(totalProteins / proteinLimit, 1) : 0 }
    var fatProgress: Double { fatLimit > 0 ? min(totalFat / fatLimit, 1) : 0 }
    var carbProgress: Double { carbLimit > 0 ? min(totalCarbs / carbLimit, 1) : 0 }

    var waterLiters: Double { Double(waterGlasses * waterGlassMl) / 1000.0 }
    var waterGoalLiters: Double { Double(waterGoalMl)  / 1000.0 }
    var waterProgress: Double {
        waterGoalMl > 0 ? min(Double(waterGlasses * waterGlassMl) / Double(waterGoalMl), 1) : 0
    }

    var isTodaySelected: Bool { isSameDay(selectedDate, Date()) }

    func canSelectDate(_ date: Date) -> Bool {
        guard let first = firstAvailableDate else { return true }
        return normalizedDay(date) >= normalizedDay(first)
    }

    func loadForDate(_ date: Date) {
        let isToday = isSameDay(date, Date())
        let dayStr = dateFormatter.string(from: date)
        Task {
            await fetchCalories(isToday: isToday, day: dayStr)
            await fetchWater(isToday: isToday, day: dayStr)
        }
    }

    func loadFirstAvailableDay() async {
        if let saved = UserDefaults.standard.string(forKey: "user_first_day"),
           let date = dateFormatter.date(from: saved) {
            firstAvailableDate = normalizedDay(date)
        }
        if let resp = try? await BackendUserService.shared.getUserCaloriesFirstDay(),
           let firstDay = resp.data?.firstDay,
           let date = dateFormatter.date(from: firstDay) {
            UserDefaults.standard.set(firstDay, forKey: "user_first_day")
            firstAvailableDate = normalizedDay(date)
            if let first = firstAvailableDate, normalizedDay(selectedDate) < first {
                selectedDate = first
                loadForDate(first)
            }
        }
    }

    private func fetchCalories(isToday: Bool, day: String) async {
        do {
            let resp = isToday
                ? try await BackendUserService.shared.getTodayCalories()
                : try await BackendUserService.shared.getCaloriesByDay(day: day)
            if resp.success, let data = resp.data { applyCaloriesData(data) }
        } catch {}
    }

    private func fetchWater(isToday: Bool, day: String) async {
        do {
            let resp = isToday
                ? try await BackendUserService.shared.getTodayWater()
                : try await BackendUserService.shared.getWaterByDay(day: day)
            if resp.success, let data = resp.data { applyWaterData(data) }
        } catch {}
    }

    func applyCaloriesData(_ data: BackendUserCaloriesData) {
        calorieLimit = data.calories ?? 2150
        proteinLimit = Double(data.proteins ?? 150)
        fatLimit = Double(data.fat ?? 70)
        carbLimit = Double(data.carbs ?? 300)
        totalCalories = data.daily?.calories ?? 0
        totalProteins = Double(data.daily?.proteins ?? 0)
        totalFat = Double(data.daily?.fat ?? 0)
        totalCarbs = Double(data.daily?.carbs ?? 0)
    }

    func applyWaterData(_ data: BackendUserWaterData) {
        let consumedMl = data.daily?.water ?? data.water ?? 0
        let goalMl     = data.daily?.goal  ?? 1750
        waterGlasses   = consumedMl / waterGlassMl
        waterGoalMl    = goalMl
    }

    func tapWaterGlass(at index: Int) {
        guard isTodaySelected, !isWaterUpdating else { return }
        let maxGlasses = maxWaterGlasses
        let safeCount  = waterGlasses.clamped(to: 0...maxGlasses)
        
        if index < safeCount {
            removeWater ()
        } else { addWater() }
    }
        
    func addWater() {
        guard isTodaySelected, !isWaterUpdating else { return }
        setWaterTo((waterGlasses + 1).clamped(to: 0...maxWaterGlasses))
    }

    func removeWater() {
        guard isTodaySelected, !isWaterUpdating, waterGlasses > 0 else { return }
        setWaterTo((waterGlasses - 1).clamped(to: 0...maxWaterGlasses))
    }

    private func setWaterTo(_ targetCount: Int) {
        let maxGlasses = maxWaterGlasses
        let previousCount = waterGlasses.clamped(to: 0...maxGlasses)
        let clamped = targetCount.clamped(to: 0...maxGlasses)
        guard clamped != previousCount else { return }

        waterGlasses = clamped
        waterError = nil
        isWaterUpdating = true

        let day = dateFormatter.string(from: selectedDate)
        let totalMl = clamped * waterGlassMl

        Task {
            defer { isWaterUpdating = false }
            do {
                let resp = try await BackendUserService.shared.updateWater(day: day, water: totalMl)
                if resp.success, let data = resp.data {
                    applyWaterData(data)
                } else {
                    waterGlasses = previousCount
                    waterError = "Failed to update water"
                }
            } catch {
                waterGlasses = previousCount
                waterError = error.localizedDescription
            }
        }
    }

    func addFood(_ item: FoodItem) {
        totalCalories += item.calories?.toCleanInt() ?? 0
        totalProteins += item.proteins.toCleanDouble()
        totalFat += item.fat.toCleanDouble()
        totalCarbs += item.carbs.toCleanDouble()
    }

    func weekDays(for date: Date) -> [Date] {
        let cal = Calendar.current
        guard let start = cal.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    func isSameDay(_ d1: Date, _ d2: Date) -> Bool { Calendar.current.isDate(d1, inSameDayAs: d2) }
    func normalizedDay(_ date: Date) -> Date { Calendar.current.startOfDay(for: date) }
    var selectedDayString: String { dateFormatter.string(from: selectedDate) }
}

extension String {
    func toCleanDouble() -> Double {
        let c = replacingOccurrences(of: ",", with: ".").filter { $0.isNumber || $0 == "." }
        return Double(c) ?? 0
    }
    func toCleanInt() -> Int {
        let c = filter { $0.isNumber }
        return Int(c) ?? 0
    }
    func toScaledDouble(multiplier: Double) -> Double { toCleanDouble() * multiplier }
}

extension Optional where Wrapped == String {
    func toCleanInt() -> Int { self?.toCleanInt()    ?? 0 }
    func toCleanDouble() -> Double { self?.toCleanDouble() ?? 0 }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
