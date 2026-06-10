import Foundation

// MARK: - Product Scan Limit (VIP gating)

struct BackendProductScanLimitResponse: Codable { let data: BackendProductScanLimitData?; let message: String?; let success: Bool? }
struct BackendProductScanLimitDecreaseResponse: Codable { let data: AnyCodable?; let message: String?; let success: Bool? }
struct BackendProductScanLimitData: Codable {
    let userId, limit, used, remaining: Int?
    let roleCode: String?; let isUnlimited, isExceeded: Bool?
    let usageDate, resetsAtUtc, timezone: String?
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"; case roleCode = "role_code"; case limit; case used; case remaining
        case isUnlimited = "is_unlimited"; case isExceeded = "is_exceeded"
        case usageDate = "usage_date"; case resetsAtUtc = "resets_at_utc"; case timezone
    }
}
// MARK: - Consumption History

struct BackendConsumptionHistoryResponse: Codable {
    let data: [BackendConsumptionHistoryItem]?; let message: String?; let success: Bool
}
struct BackendConsumptionHistoryItem: Codable, Identifiable {
    var id: String { date ?? UUID().uuidString }
    let date: String?
    let calories, caloriesGoal: Int?
    let proteins, proteinGoal: Int?
    let carbs, carbsGoal: Int?
    let fat, fatGoal: Int?
    let water, waterGoal: Int?
    let fiber, sodium, sugar, cholesterol: Int?
    let vitaminA, vitaminB6, vitaminB9, vitaminB12, vitaminC, vitaminD, vitaminE: Double?
    enum CodingKeys: String, CodingKey {
        case date; case calories; case caloriesGoal = "calories_goal"
        case proteins; case proteinGoal = "protein_goal"
        case carbs; case carbsGoal = "carbs_goal"
        case fat; case fatGoal = "fat_goal"
        case water; case waterGoal = "water_goal"
        case fiber; case sodium; case sugar; case cholesterol
        case vitaminA = "vitamin_a"; case vitaminB6 = "vitamin_b6"; case vitaminB9 = "vitamin_b9"
        case vitaminB12 = "vitamin_b12"; case vitaminC = "vitamin_c"; case vitaminD = "vitamin_d"; case vitaminE = "vitamin_e"
    }
}

//history eating
struct BackendUserFirstDayResponse: Codable { let data: BackendUserFirstDayData?; let message: String?; let success: Bool }
struct BackendUserFirstDayData: Codable {
    let firstDay: String?
    enum CodingKeys: String, CodingKey { case firstDay = "first_day" }
}

