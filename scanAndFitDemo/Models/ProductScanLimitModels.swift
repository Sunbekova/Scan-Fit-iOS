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

struct BackendConsumptionHistoryResponse: Codable { let data: [BackendConsumptionHistoryItem]?; let message: String?; let success: Bool }

struct BackendConsumptionHistoryItem: Codable, Identifiable {
    var id: String { date ?? UUID().uuidString }
    
    let calories, caloriesGoal, carbs, carbsGoal, cholesterol, cholesterolGoal: Int?
    let fat, fatGoal, fiber, fiberGoal, proteinGoal, proteins, sodium, sodiumGoal, sugar, sugarGoal, water, waterGoal: Int?
    let vitaminA, vitaminAGoal, vitaminB6, vitaminB6Goal, vitaminB9, vitaminB9Goal: Double?
    let vitaminB12, vitaminB12Goal, vitaminC, vitaminCGoal, vitaminD, vitaminDGoal, vitaminE, vitaminEGoal: Double?
    let date: String?
    enum CodingKeys: String, CodingKey {
        case calories; case caloriesGoal = "calories_goal"
        case carbs; case carbsGoal = "carbs_goal"
        case cholesterol; case cholesterolGoal = "cholesterol_goal"
        case fat; case fatGoal = "fat_goal"; case fiber; case fiberGoal = "fiber_goal"
        case proteinGoal = "protein_goal"; case proteins; case sodium; case sodiumGoal = "sodium_goal"
        case sugar; case sugarGoal = "sugar_goal"; case water; case waterGoal = "water_goal"
        case vitaminA = "vitamin_a"; case vitaminAGoal = "vitamin_a_goal"
        case vitaminB6 = "vitamin_b6"; case vitaminB6Goal = "vitamin_b6_goal"
        case vitaminB9 = "vitamin_b9"; case vitaminB9Goal = "vitamin_b9_goal"
        case vitaminB12 = "vitamin_b12"; case vitaminB12Goal = "vitamin_b12_goal"
        case vitaminC = "vitamin_c"; case vitaminCGoal = "vitamin_c_goal"
        case vitaminD = "vitamin_d"; case vitaminDGoal = "vitamin_d_goal"
        case vitaminE = "vitamin_e"; case vitaminEGoal = "vitamin_e_goal"
        case date
    }
}

//history eating
struct BackendUserFirstDayResponse: Codable { let data: BackendUserFirstDayData?; let message: String?; let success: Bool }
struct BackendUserFirstDayData: Codable {
    let firstDay: String?
    enum CodingKeys: String, CodingKey { case firstDay = "first_day" }
}

