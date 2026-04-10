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
    let date: String?

    enum CodingKeys: String, CodingKey {
        case id, calories, date
        case userId = "user_id"
    }
}

struct BackendCreateUserCaloriesRequest: Codable {
    let calories: Int
}

extension BackendDietType: Nameable, Activeable {}
extension BackendDisease: Nameable, Activeable {}
