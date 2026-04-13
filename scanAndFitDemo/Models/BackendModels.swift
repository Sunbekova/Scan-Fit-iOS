import Foundation

// MARK: - Backend Base URL
// Backend Gateway runs at: http://46.101.137.109:3000


struct BackendRegisterRequest: Codable {
    let username, email, password, passwordConfirmation: String
    enum CodingKeys: String, CodingKey {
        case username, email, password
        case passwordConfirmation = "password_confirmation"
    }
}
struct BackendLoginRequest: Codable { let email, password: String }
struct BackendForgotPasswordRequest: Codable { let email: String }
struct BackendVerifyPinRequest: Codable {
    let email, pinCode: String
    enum CodingKeys: String, CodingKey { case email; case pinCode = "pin_code" }
}
struct BackendResetPasswordRequest: Codable {
    let email, token, newPassword, newPasswordConfirmation: String
    enum CodingKeys: String, CodingKey {
        case email, token
        case newPassword = "new_password"
        case newPasswordConfirmation = "new_password_confirmation"
    }
}
struct BackendRefreshTokenRequest: Codable {
    let refreshToken: String
    enum CodingKeys: String, CodingKey { case refreshToken = "refresh_token" }
}

struct BackendAuthResponse: Codable {
    let data: BackendAuthData?
    let message: String?
    let success: Bool
}

struct BackendAuthData: Codable {
    let id: Int?
    let accessToken, refreshToken, tokenType: String
    let expiresIn: Int
    let role: BackendUserRole?
    enum CodingKeys: String, CodingKey {
        case id
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case role
    }
}
struct BackendUserRole: Codable { let id: Int; let name, code: String }
struct BackendBaseResponse: Codable { let message: String?; let success: Bool? }
struct BackendVerifyPinResponse: Codable { let data: BackendVerifyPinData?; let message: String?; let success: Bool }
struct BackendVerifyPinData: Codable { let token: String }
//user acc
struct BackendUserAccountResponse: Codable { let data: BackendUserAccountData?; let message: String?; let success: Bool }
struct BackendUserAccountData: Codable {
    let id: Int; let email: String; let username: String?
    let birthDate, mygoal, photo, createdAt, updatedAt: String?
    enum CodingKeys: String, CodingKey {
        case id, email, username, mygoal, photo
        case birthDate = "birth_date"; case createdAt = "created_at"; case updatedAt = "updated_at"
    }
}
//registr status
struct BackendRegistrationStatusResponse: Codable { let data: BackendRegistrationStatusData?; let message: String?; let success: Bool }
struct BackendRegistrationStatusData: Codable {
    let isFinishedRegister: Bool?
    enum CodingKeys: String, CodingKey { case isFinishedRegister = "is_finished_register" }
}
struct BackendUpdateRegistrationStatusRequest: Codable {
    let isFinishedRegister: Bool
    enum CodingKeys: String, CodingKey { case isFinishedRegister = "is_finished_register" }
}
//role
struct BackendUserRoleResponse: Codable { let data: BackendUserRoleData?; let message: String?; let success: Bool }
struct BackendUserRoleData: Codable { let id: Int?; let name, code: String? }
//measure
struct BackendUserMeasureResponse: Codable { let data: BackendUserMeasureData?; let message: String?; let success: Bool }
struct BackendUserMeasureData: Codable {
    let id, userId: Int?
    let age, birthDate, gender: String?
    let bloodPressure, bmi, cholesterol, height, weight: Int?
    let dailyCaloriesGoal, dailyWaterGoal: Int?
    let createdAt, updatedAt: String?
    enum CodingKeys: String, CodingKey {
        case id; case userId = "user_id"; case age; case birthDate = "birth_date"; case gender
        case bloodPressure = "blood_pressure"; case bmi; case cholesterol; case height; case weight
        case dailyCaloriesGoal = "daily_calories_goal"; case dailyWaterGoal = "daily_water_goal"
        case createdAt = "created_at"; case updatedAt = "updated_at"
    }
}
struct BackendUserMeasureRequest: Codable {
    let age, birthDate, gender: String
    let bloodPressure, bmi, cholesterol, dailyCaloriesGoal, dailyWaterGoal, height, userId, weight: Int
    enum CodingKeys: String, CodingKey {
        case age; case birthDate = "birth_date"; case gender
        case bloodPressure = "blood_pressure"; case bmi; case cholesterol
        case dailyCaloriesGoal = "daily_calories_goal"; case dailyWaterGoal = "daily_water_goal"
        case height; case userId = "user_id"; case weight
    }
}
struct BackendUpdateUserMeasureRequest: Codable {
    let age, birthDate, gender: String?
    let bloodPressure, bmi, cholesterol, dailyCaloriesGoal, dailyWaterGoal, height, weight: Int?
    enum CodingKeys: String, CodingKey {
        case age; case birthDate = "birth_date"; case gender
        case bloodPressure = "blood_pressure"; case bmi; case cholesterol
        case dailyCaloriesGoal = "daily_calories_goal"; case dailyWaterGoal = "daily_water_goal"
        case height; case weight
    }
}
//user detail
struct BackendUserDetailsResponse: Codable { let data: BackendUserDetailsData?; let message: String?; let success: Bool }
struct BackendUserDetailsData: Codable {
    let activeDietTypes, activeDietaryPreferences, activeHealthConditions: [BackendDietType]?
    let activeDiseases: [BackendDisease]?
    let measure: BackendUserMeasureData?
    let user: BackendUserAccountData?
    let weightManagement: BackendWeightManagementData?
    enum CodingKeys: String, CodingKey {
        case activeDietTypes = "active_diet_types"
        case activeDietaryPreferences = "active_dietary_preferences"
        case activeHealthConditions = "active_health_conditions"
        case activeDiseases = "active_diseases"
        case measure; case user
        case weightManagement = "weight_management"
    }
}
//diet types
struct BackendDietTypeListResponse: Codable { let data: [BackendDietType]?; let message: String?; let success: Bool }
struct BackendDietType: Codable, Identifiable {
    let id: Int; let name: String; let isActive: Bool; let category: String?
    enum CodingKeys: String, CodingKey { case id; case name; case isActive = "is_active"; case category }
}
struct BackendUpdateDietTypeRequest: Codable {
    let isActive: Bool
    enum CodingKeys: String, CodingKey { case isActive = "is_active" }
}
struct BackendUpdateDietTypeResponse: Codable { let message: String?; let success: Bool }
//disease
struct BackendDiseaseListResponse: Codable { let data: [BackendDisease]?; let message: String?; let success: Bool }
struct BackendDisease: Codable, Identifiable {
    let id: Int
    let code: String?
    let name: String?
    let description: String?
    let diseaseLevel: BackendDiseaseLevel?
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, code, name, description
        case diseaseLevel = "disease_level"
        case isActive = "is_active"
    }
}
struct BackendDiseaseLevelListResponse: Codable { let data: [BackendDiseaseLevel]?; let message: String?; let success: Bool }
struct BackendDiseaseLevel: Codable, Identifiable { let id: Int; let code, name: String? }
struct BackendUpdateDiseaseRequest: Codable {
    let diseaseLevelId: Int; let isActive: Bool
    enum CodingKeys: String, CodingKey { case diseaseLevelId = "disease_level_id"; case isActive = "is_active" }
}
//weight
struct BackendWeightManagementResponse: Codable { let data: BackendWeightManagementData?; let message: String?; let success: Bool }
struct BackendWeightManagementData: Codable {
    let id, userId, targetWeight, weeklyWeightChange: Int?
    let goal, targetDate, createdAt, updatedAt: String?
    enum CodingKeys: String, CodingKey {
        case id; case userId = "user_id"; case goal
        case targetDate = "target_date"; case targetWeight = "target_weight"
        case weeklyWeightChange = "weekly_weight_change"
        case createdAt = "created_at"; case updatedAt = "updated_at"
    }
}
struct BackendUpdateWeightManagementRequest: Codable {
    let goal, targetDate: String?; let targetWeight, weeklyWeightChange: Int?
    enum CodingKeys: String, CodingKey {
        case goal; case targetDate = "target_date"
        case targetWeight = "target_weight"; case weeklyWeightChange = "weekly_weight_change"
    }
}
//calories
struct BackendUserCaloriesResponse: Codable { let data: BackendUserCaloriesData?; let message: String?; let success: Bool }
struct BackendUserCaloriesData: Codable {
    let id, userId, calories, carbs, fat, fiber, proteins, sodium, sugar, cholesterol: Int?
    let vitaminA, vitaminB6, vitaminB9, vitaminB12, vitaminC, vitaminD, vitaminE: Double?
    let day: String?; let daily: BackendUserCaloriesDaily?; let createdAt, updatedAt: String?
    enum CodingKeys: String, CodingKey {
        case id; case userId = "user_id"; case calories; case carbs; case fat; case fiber; case proteins
        case sodium; case sugar; case cholesterol
        case vitaminA = "vitamin_a"; case vitaminB6 = "vitamin_b6"; case vitaminB9 = "vitamin_b9"
        case vitaminB12 = "vitamin_b12"; case vitaminC = "vitamin_c"; case vitaminD = "vitamin_d"; case vitaminE = "vitamin_e"
        case day; case daily; case createdAt = "created_at"; case updatedAt = "updated_at"
    }
}
struct BackendUserCaloriesDaily: Codable {
    let id: Int?; let day: String?
    let calories, carbs, fat, fiber, proteins, sodium, sugar, cholesterol: Int?
    let vitaminA, vitaminB6, vitaminB9, vitaminB12, vitaminC, vitaminD, vitaminE: Double?
    let createdAt, updatedAt: String?
    enum CodingKeys: String, CodingKey {
        case id; case day; case calories; case carbs; case fat; case fiber; case proteins
        case sodium; case sugar; case cholesterol
        case vitaminA = "vitamin_a"; case vitaminB6 = "vitamin_b6"; case vitaminB9 = "vitamin_b9"
        case vitaminB12 = "vitamin_b12"; case vitaminC = "vitamin_c"; case vitaminD = "vitamin_d"; case vitaminE = "vitamin_e"
        case createdAt = "created_at"; case updatedAt = "updated_at"
    }
}
struct BackendUpdateUserCaloriesRequest: Codable {
    let calories, carbs, fat, proteins: Int
    let fiber, sodium, sugar, cholesterol: Int?
    let vitaminA, vitaminB6, vitaminB9, vitaminB12, vitaminC, vitaminD, vitaminE: Double?
    enum CodingKeys: String, CodingKey {
        case calories; case carbs; case fat; case proteins; case fiber; case sodium; case sugar; case cholesterol
        case vitaminA = "vitamin_a"; case vitaminB6 = "vitamin_b6"; case vitaminB9 = "vitamin_b9"
        case vitaminB12 = "vitamin_b12"; case vitaminC = "vitamin_c"; case vitaminD = "vitamin_d"; case vitaminE = "vitamin_e"
    }
}

//water
struct BackendUserWaterResponse: Codable { let data: BackendUserWaterData?; let message: String?; let success: Bool }
struct BackendUserWaterData: Codable {
    let id, userId, water: Int?; let day: String?
    let daily: BackendUserWaterDaily?; let createdAt, updatedAt: String?
    enum CodingKeys: String, CodingKey {
        case id; case userId = "user_id"; case water; case day; case daily
        case createdAt = "created_at"; case updatedAt = "updated_at"
    }
}
struct BackendUserWaterDaily: Codable {
    let id: Int?; let day: String?; let water, goal: Int?; let createdAt, updatedAt: String?
    enum CodingKeys: String, CodingKey {
        case id; case day; case water; case goal; case createdAt = "created_at"; case updatedAt = "updated_at"
    }
}
struct BackendUpdateUserWaterRequest: Codable { let water: Int }
//dayly eat
struct BackendCreateUserDailyEatRequest: Codable {
    let calorie, carbohydrate, cholesterol, fats, fiber: Int
    let portion: Double; let productName: String
    let protein, sodium, sugar: Int
    let vitaminA, vitaminB6, vitaminB9, vitaminB12, vitaminC, vitaminD, vitaminE: Double?
    enum CodingKeys: String, CodingKey {
        case calorie; case carbohydrate; case cholesterol; case fats; case fiber; case portion
        case productName = "product_name"; case protein; case sodium; case sugar
        case vitaminA = "vitamin_a"; case vitaminB6 = "vitamin_b6"; case vitaminB9 = "vitamin_b9"
        case vitaminB12 = "vitamin_b12"; case vitaminC = "vitamin_c"; case vitaminD = "vitamin_d"; case vitaminE = "vitamin_e"
    }
}
struct BackendCreateUserDailyEatResponse: Codable { let message: String?; let success: Bool? }
struct BackendCreateProductScanRequest: Codable {
    let productName: String; let scanInformation: AnyCodable
    enum CodingKeys: String, CodingKey { case productName = "product_name"; case scanInformation = "scan_information" }
}
struct BackendCreateProductScanResponse: Codable { let message: String?; let success: Bool? }
struct BackendProductScanResponse: Codable { let data: AnyCodable?; let message: String?; let success: Bool }

// MARK: - AnyCodable helper
struct AnyCodable: Codable {
    let value: Any?
    init(_ value: Any?) { self.value = value }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { value = nil }
        else if let b = try? container.decode(Bool.self) { value = b }
        else if let i = try? container.decode(Int.self) { value = i }
        else if let d = try? container.decode(Double.self) { value = d }
        else if let s = try? container.decode(String.self) { value = s }
        else if let a = try? container.decode([AnyCodable].self) { value = a.map(\.value) }
        else if let o = try? container.decode([String: AnyCodable].self) { value = o.mapValues(\.value) }
        else { value = nil }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case nil: try container.encodeNil()
        case let b as Bool: try container.encode(b)
        case let i as Int: try container.encode(i)
        case let d as Double: try container.encode(d)
        case let s as String: try container.encode(s)
        case let a as [Any?]: try container.encode(a.map { AnyCodable($0) })
        case let o as [String: Any?]: try container.encode(o.mapValues { AnyCodable($0) })
        default:                try container.encodeNil()
        }
    }
}
extension BackendDietType: Nameable, Activeable {
    var displayName: String { return name }
}

extension BackendDisease: Nameable, Activeable {
    var displayName: String {
        return self.name ?? "Unknown Condition"
    }
}
