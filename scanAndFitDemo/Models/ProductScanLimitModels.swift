import Foundation

// MARK: - Product Scan Limit (VIP gating)

struct BackendProductScanLimitResponse: Codable {
    let data: BackendProductScanLimitData?
    let message: String?
    let success: Bool?
}

struct BackendProductScanLimitData: Codable {
    let userId: Int?
    let roleCode: String?
    let limit: Int?
    let used: Int?
    let remaining: Int?
    let isUnlimited: Bool?
    let isExceeded: Bool?
    let usageDate: String?
    let resetsAtUtc: String?
    let timezone: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case roleCode = "role_code"
        case limit, used, remaining
        case isUnlimited = "is_unlimited"
        case isExceeded = "is_exceeded"
        case usageDate = "usage_date"
        case resetsAtUtc = "resets_at_utc"
        case timezone
    }
}

struct BackendProductScanLimitDecreaseResponse: Codable {
    let message: String?
    let success: Bool?
}

// MARK: - Consumption History

struct BackendConsumptionHistoryResponse: Codable {
    let data: [BackendConsumptionHistoryItem]?
    let message: String?
    let success: Bool
}

struct BackendConsumptionHistoryItem: Codable, Identifiable {
    var id: String { date ?? UUID().uuidString }
    let date: String?
    let calories: Int?
    let caloriesGoal: Int?
    let carbs: Int?
    let carbsGoal: Int?
    let fat: Int?
    let fatGoal: Int?
    let proteins: Int?
    let proteinGoal: Int?
    let fiber: Int?
    let fiberGoal: Int?
    let sodium: Int?
    let sodiumGoal: Int?
    let sugar: Int?
    let sugarGoal: Int?
    let cholesterol: Int?
    let cholesterolGoal: Int?
    let water: Int?
    let waterGoal: Int?
    let vitaminA: Double?
    let vitaminAGoal: Double?
    let vitaminC: Double?
    let vitaminCGoal: Double?

    enum CodingKeys: String, CodingKey {
        case date, calories, carbs, fat, fiber, proteins, sodium, sugar, cholesterol, water
        case caloriesGoal = "calories_goal"
        case carbsGoal = "carbs_goal"
        case fatGoal = "fat_goal"
        case fiberGoal = "fiber_goal"
        case proteinGoal = "protein_goal"
        case sodiumGoal = "sodium_goal"
        case sugarGoal = "sugar_goal"
        case cholesterolGoal = "cholesterol_goal"
        case waterGoal = "water_goal"
        case vitaminA = "vitamin_a"
        case vitaminAGoal = "vitamin_a_goal"
        case vitaminC = "vitamin_c"
        case vitaminCGoal = "vitamin_c_goal"
    }
}

struct BackendUserFirstDayResponse: Codable {
    let data: BackendUserFirstDayData?
    let message: String?
    let success: Bool
}

struct BackendUserFirstDayData: Codable {
    let firstDay: String?
    enum CodingKeys: String, CodingKey {
        case firstDay = "first_day"
    }
}
