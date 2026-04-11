import Foundation

// MARK: - Backend Base URL
// Backend Gateway runs at: http://46.101.137.109:3000


struct BackendRegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
    let passwordConfirmation: String
    enum CodingKeys: String, CodingKey {
        case username, email, password
        case passwordConfirmation = "password_confirmation"
    }
}

struct BackendLoginRequest: Codable {
    let email: String
    let password: String
}

struct BackendForgotPasswordRequest: Codable {
    let email: String
}

struct BackendVerifyPinRequest: Codable {
    let email: String
    let pinCode: String
    enum CodingKeys: String, CodingKey {
        case email
        case pinCode = "pin_code"
    }
}

struct BackendResetPasswordRequest: Codable {
    let email: String
    let token: String
    let newPassword: String
    let newPasswordConfirmation: String
    enum CodingKeys: String, CodingKey {
        case email, token
        case newPassword = "new_password"
        case newPasswordConfirmation = "new_password_confirmation"
    }
}

struct BackendRefreshTokenRequest: Codable {
    let refreshToken: String
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct BackendAuthResponse: Codable {
    let data: BackendAuthData?
    let message: String?
    let success: Bool
}

struct BackendAuthData: Codable {
    let id: Int?
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String
    let tokenType: String
    let role: BackendUserRole?
    enum CodingKeys: String, CodingKey {
        case id
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case role
    }
}

struct BackendUserRole: Codable {
    let id: Int
    let name: String
    let code: String
}

struct BackendBaseResponse: Codable {
    let message: String?
    let success: Bool?
}

struct BackendVerifyPinResponse: Codable {
    let data: BackendVerifyPinData?
    let message: String?
    let success: Bool
}

struct BackendVerifyPinData: Codable {
    let token: String
}


struct BackendUserAccountResponse: Codable {
    let data: BackendUserAccountData?
    let message: String?
    let success: Bool
}

struct BackendUserAccountData: Codable {
    let id: Int
    let email: String
    let username: String?
    let birthDate: String?
    let mygoal: String?
    let photo: String?
    let createdAt: String?
    let updatedAt: String?
    enum CodingKeys: String, CodingKey {
        case id, email, username, mygoal, photo
        case birthDate = "birth_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Rol'

struct BackendUserRoleResponse: Codable {
    let data: BackendUserRoleData?
    let message: String?
    let success: Bool
}

struct BackendUserRoleData: Codable {
    let code: String?
    let name: String?
}

struct BackendUserMeasureRequest: Codable {
    let age: String
    let birthDate: String
    let bloodPressure: Int
    let bmi: Int
    let cholesterol: Int
    let dailyCaloriesGoal: Int
    let dailyWaterGoal: Int
    let gender: String
    let height: Int
    let userId: Int
    let weight: Int
    enum CodingKeys: String, CodingKey {
        case age, bmi, cholesterol, gender, height, weight
        case birthDate = "birth_date"
        case bloodPressure = "blood_pressure"
        case dailyCaloriesGoal = "daily_calories_goal"
        case dailyWaterGoal = "daily_water_goal"
        case userId = "user_id"
    }
}

struct BackendUpdateUserMeasureRequest: Codable {
    let age: String
    let birthDate: String
    let bloodPressure: Int
    let bmi: Int
    let cholesterol: Int
    let dailyCaloriesGoal: Int
    let dailyWaterGoal: Int
    let gender: String
    let height: Int
    let weight: Int
    enum CodingKeys: String, CodingKey {
        case age, bmi, cholesterol, gender, height, weight
        case birthDate = "birth_date"
        case bloodPressure = "blood_pressure"
        case dailyCaloriesGoal = "daily_calories_goal"
        case dailyWaterGoal = "daily_water_goal"
    }
}

struct BackendUserMeasureResponse: Codable {
    let data: BackendUserMeasureData?
    let message: String?
    let success: Bool
}

struct BackendUserMeasureData: Codable {
    let id: Int
    let userId: Int
    let age: String?
    let birthDate: String?
    let bloodPressure: Int?
    let bmi: Int?
    let cholesterol: Int?
    let createdAt: String?
    let dailyCaloriesGoal: Int?
    let dailyWaterGoal: Int?
    let gender: String?
    let height: Int?
    let updatedAt: String?
    let weight: Int?
    enum CodingKeys: String, CodingKey {
        case id, age, bmi, cholesterol, gender, height, weight
        case userId = "user_id"
        case birthDate = "birth_date"
        case bloodPressure = "blood_pressure"
        case createdAt = "created_at"
        case dailyCaloriesGoal = "daily_calories_goal"
        case dailyWaterGoal = "daily_water_goal"
        case updatedAt = "updated_at"
    }
}

struct BackendDietTypeListResponse: Codable {
    let data: [BackendDietType]?
    let message: String?
    let success: Bool
}

struct BackendDietType: Codable, Identifiable {
    let id: Int
    let name: String
    let isActive: Bool
    let category: String?
    enum CodingKeys: String, CodingKey {
        case id, name, category
        case isActive = "is_active"
    }
}

struct BackendUpdateDietTypeRequest: Codable {
    let isActive: Bool
    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
    }
}

struct BackendUpdateDietTypeResponse: Codable {
    let message: String?
    let success: Bool
}

struct BackendDiseaseListResponse: Codable {
    let data: [BackendDisease]?
    let message: String?
    let success: Bool
}

struct BackendDisease: Codable, Identifiable {
    let id: Int
    let code: String?
    let name: String
    let description: String?
    let diseaseLevel: BackendDiseaseLevel?
    let isActive: Bool
    enum CodingKeys: String, CodingKey {
        case id, code, name, description
        case diseaseLevel = "disease_level"
        case isActive = "is_active"
    }
}

struct BackendDiseaseLevelListResponse: Codable {
    let data: [BackendDiseaseLevel]?
    let message: String?
    let success: Bool
}

struct BackendDiseaseLevel: Codable, Identifiable {
    let id: Int
    let code: String?
    let name: String
}

struct BackendUpdateDiseaseRequest: Codable {
    let diseaseLevelId: Int
    let isActive: Bool
    enum CodingKeys: String, CodingKey {
        case diseaseLevelId = "disease_level_id"
        case isActive = "is_active"
    }
}

struct BackendWeightManagementResponse: Codable {
    let data: BackendWeightManagementData?
    let message: String?
    let success: Bool
}

struct BackendWeightManagementData: Codable {
    let id: Int
    let goal: String?
    let targetDate: String?
    let targetWeight: Int?
    let weeklyWeightChange: Int?
    enum CodingKeys: String, CodingKey {
        case id, goal
        case targetDate = "target_date"
        case targetWeight = "target_weight"
        case weeklyWeightChange = "weekly_weight_change"
    }
}

struct BackendUpdateWeightManagementRequest: Codable {
    let goal: String?
    let targetDate: String?
    let targetWeight: Int?
    let weeklyWeightChange: Int?
    enum CodingKeys: String, CodingKey {
        case goal
        case targetDate = "target_date"
        case targetWeight = "target_weight"
        case weeklyWeightChange = "weekly_weight_change"
    }
}

struct BackendUserCaloriesResponse: Codable {
    let data: BackendUserCaloriesData?
    let message: String?
    let success: Bool
}

struct BackendUserCaloriesData: Codable {
    let id: Int?
    let userId: Int?
    let calories: Int?
    let proteins: Double?
    let fat: Double?
    let carbs: Double?
    let fiber: Double?
    let sodium: Double?
    let sugar: Double?
    let cholesterol: Double?
    let vitaminA: Double?
    let vitaminB12: Double?
    let vitaminB6: Double?
    let vitaminB9: Double?
    let vitaminC: Double?
    let vitaminD: Double?
    let vitaminE: Double?
    let daily: BackendDailyNutrition?
    enum CodingKeys: String, CodingKey {
        case id, calories, proteins, fat, carbs, fiber, sodium, sugar, cholesterol, daily
        case userId = "user_id"
        case vitaminA = "vitamin_a"
        case vitaminB12 = "vitamin_b12"
        case vitaminB6 = "vitamin_b6"
        case vitaminB9 = "vitamin_b9"
        case vitaminC = "vitamin_c"
        case vitaminD = "vitamin_d"
        case vitaminE = "vitamin_e"
    }
}

struct BackendDailyNutrition: Codable {
    let calories: Int?
    let proteins: Double?
    let fat: Double?
    let carbs: Double?
    let fiber: Double?
    let sodium: Double?
    let sugar: Double?
    let cholesterol: Double?
    let vitaminA: Double?
    let vitaminB12: Double?
    let vitaminB6: Double?
    let vitaminB9: Double?
    let vitaminC: Double?
    let vitaminD: Double?
    let vitaminE: Double?
    let water: Int?
    let goal: Int?
    enum CodingKeys: String, CodingKey {
        case calories, proteins, fat, carbs, fiber, sodium, sugar, cholesterol, water, goal
        case vitaminA = "vitamin_a"
        case vitaminB12 = "vitamin_b12"
        case vitaminB6 = "vitamin_b6"
        case vitaminB9 = "vitamin_b9"
        case vitaminC = "vitamin_c"
        case vitaminD = "vitamin_d"
        case vitaminE = "vitamin_e"
    }
}

struct BackendUpdateUserCaloriesRequest: Codable {
    let calories: Int
    let carbs: Int
    let fat: Int
    let proteins: Int
    let fiber: Int?
    let sodium: Int?
    let sugar: Int?
    let cholesterol: Int?
    let vitaminA: Double?
    let vitaminB12: Double?
    let vitaminB6: Double?
    let vitaminB9: Double?
    let vitaminC: Double?
    let vitaminD: Double?
    let vitaminE: Double?
    enum CodingKeys: String, CodingKey {
        case calories, carbs, fat, proteins, fiber, sodium, sugar, cholesterol
        case vitaminA = "vitamin_a"
        case vitaminB12 = "vitamin_b12"
        case vitaminB6 = "vitamin_b6"
        case vitaminB9 = "vitamin_b9"
        case vitaminC = "vitamin_c"
        case vitaminD = "vitamin_d"
        case vitaminE = "vitamin_e"
    }
}

struct BackendUserWaterResponse: Codable {
    let data: BackendUserWaterData?
    let message: String?
    let success: Bool
}

struct BackendUserWaterData: Codable {
    let daily: BackendDailyWater?
    let water: Int?
}

struct BackendDailyWater: Codable {
    let water: Int?
    let goal: Int?
}

struct BackendUpdateUserWaterRequest: Codable {
    let water: Int
}

struct BackendCreateUserDailyEatRequest: Codable {
    let calorie: Int
    let carbohydrate: Int
    let cholesterol: Int?
    let fats: Int
    let fiber: Int?
    let portion: Double
    let productName: String
    let protein: Int
    let sodium: Int?
    let sugar: Int?
    let vitaminA: Double?
    let vitaminB12: Double?
    let vitaminB6: Double?
    let vitaminB9: Double?
    let vitaminC: Double?
    let vitaminD: Double?
    let vitaminE: Double?
    enum CodingKeys: String, CodingKey {
        case calorie, carbohydrate, cholesterol, fats, fiber, portion, protein, sodium, sugar
        case productName = "product_name"
        case vitaminA = "vitamin_a"
        case vitaminB12 = "vitamin_b12"
        case vitaminB6 = "vitamin_b6"
        case vitaminB9 = "vitamin_b9"
        case vitaminC = "vitamin_c"
        case vitaminD = "vitamin_d"
        case vitaminE = "vitamin_e"
    }
}

struct BackendCreateUserDailyEatResponse: Codable {
    let message: String?
    let success: Bool
}

struct BackendCreateProductScanRequest: Codable {
    let productName: String
    let scanInformation: AnyCodable
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case scanInformation = "scan_information"
    }
}

struct BackendProductScanResponse: Codable {
    let data: AnyCodable?
    let message: String?
    let success: Bool
}

struct BackendCreateProductScanResponse: Codable {
    let message: String?
    let success: Bool
}

struct BackendUserDetailsResponse: Codable {
    let data: BackendUserDetailsData?
    let message: String?
    let success: Bool
}

struct BackendUserDetailsData: Codable {
    let activeDietTypes: [BackendDietType]?
    let activeDietaryPreferences: [BackendDietType]?
    let activeDiseases: [BackendDisease]?
    let activeHealthConditions: [BackendDietType]?
    let measure: BackendUserMeasureData?
    let user: BackendUserAccountData?
    let weightManagement: BackendWeightManagementData?
    enum CodingKeys: String, CodingKey {
        case measure, user
        case activeDietTypes = "active_diet_types"
        case activeDietaryPreferences = "active_dietary_preferences"
        case activeDiseases = "active_diseases"
        case activeHealthConditions = "active_health_conditions"
        case weightManagement = "weight_management"
    }
}

extension BackendDietType: Nameable, Activeable {}
extension BackendDisease: Nameable, Activeable {}

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Int.self) { value = v }
        else if let v = try? container.decode(Double.self) { value = v }
        else if let v = try? container.decode(Bool.self) { value = v }
        else if let v = try? container.decode(String.self) { value = v }
        else if let v = try? container.decode([AnyCodable].self) { value = v.map { $0.value } }
        else if let v = try? container.decode([String: AnyCodable].self) { value = v.mapValues { $0.value } }
        else { value = NSNull() }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as Bool: try container.encode(v)
        case let v as String: try container.encode(v)
        case let v as [Any]: try container.encode(v.map { AnyCodable($0) })
        case let v as [String: Any]: try container.encode(v.mapValues { AnyCodable($0) })
        default: try container.encodeNil()
        }
    }
}
