import Foundation
import SwiftData

struct FoodItem: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let imageURL: String?
    let calories: String?
    let grade: String?
    var isFavorite: Bool
    let proteins: String
    let fat: String
    let carbs: String
    let description: String
    let cholesterol: String?
    let sodium: String?
    let sugars: String?
    let fiber: String?
    let ingredients: String?
    let vitaminA: String?
    let vitaminB12: String?
    let vitaminB6: String?
    let vitaminB9: String?
    let vitaminC: String?
    let vitaminD: String?
    let vitaminE: String?

    init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String? = nil,
        imageURL: String? = nil,
        calories: String? = "0",
        grade: String? = "B",
        isFavorite: Bool = false,
        proteins: String = "0g",
        fat: String = "0g",
        carbs: String = "0g",
        description: String = "",
        cholesterol: String? = "0mg",
        sodium: String? = "0mg",
        sugars: String? = "0g",
        fiber: String? = "0g",
        ingredients: String? = nil,
        vitaminA: String? = nil,
        vitaminB12: String? = nil,
        vitaminB6: String? = nil,
        vitaminB9: String? = nil,
        vitaminC: String? = nil,
        vitaminD: String? = nil,
        vitaminE: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
        self.calories = calories
        self.grade = grade
        self.isFavorite = isFavorite
        self.proteins = proteins
        self.fat = fat
        self.carbs = carbs
        self.description = description
        self.cholesterol = cholesterol
        self.sodium = sodium
        self.sugars = sugars
        self.fiber = fiber
        self.ingredients = ingredients
        self.vitaminA = vitaminA; self.vitaminB12 = vitaminB12; self.vitaminB6 = vitaminB6
        self.vitaminB9 = vitaminB9; self.vitaminC = vitaminC; self.vitaminD = vitaminD; self.vitaminE = vitaminE
    }
}

// MARK: - Open Food Facts API

struct FoodAPIResponse: Codable {
    let products: [APIProduct]
}

struct APIProduct: Codable {
    let code: String?
    let productName: String?
    let brands: String?
    let imageURL: String?
    let nutriscoreGrade: String?
    let nutriments: Nutriments?
    let nutrimentsEstimated: NutrimentsEstimated?
    let ingredientsText: String?
    let ingredientsTextEn: String?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case imageURL = "image_url"
        case nutriscoreGrade = "nutriscore_grade"
        case nutriments
        case nutrimentsEstimated = "nutriments_estimated"
        case ingredientsText = "ingredients_text"
        case ingredientsTextEn = "ingredients_text_en"
    }
}

extension APIProduct {
    func toFoodItem() -> FoodItem {
        let n = nutriments
        let est = nutrimentsEstimated
        let kcal = n?.energyKcalServing ?? n?.energyKcal100g ?? 0
        return FoodItem(
            id: code ?? UUID().uuidString,
            title: productName ?? "Unknown Product",
            subtitle: brands,
            imageURL: imageURL,
            calories: "\(Int(kcal)) kcal",
            grade: nutriscoreGrade?.uppercased() ?? "B",
            proteins: "\(n?.proteinsServing ?? n?.proteins100g ?? 0)g",
            fat: "\(n?.fatServing ?? n?.fat100g ?? 0)g",
            carbs: "\(n?.carbohydratesServing ?? n?.carbohydrates100g ?? 0)g",
            description: "",
            cholesterol: "\(n?.cholesterolServing ?? n?.cholesterol100g ?? 0)mg",
            sodium: "\(n?.sodiumServing ?? n?.sodium100g ?? 0)mg",
            sugars: "\(n?.sugarsServing ?? n?.sugars100g ?? 0)g",
            fiber: "\(n?.fiberServing ?? n?.fiber100g ?? 0)g",
            ingredients: ingredientsText ?? ingredientsTextEn,
            vitaminA: est?.vitaminA100g.map { "\($0)mcg" },
            vitaminB12: est?.vitaminB12100g.map { "\($0)mcg" },
            vitaminB6: est?.vitaminB6100g.map { "\($0)mg" },
            vitaminB9: est?.vitaminB9100g.map { "\($0)mcg" },
            vitaminC: est?.vitaminC100g.map { "\($0)mg" },
            vitaminD: est?.vitaminD100g.map { "\($0)mcg" },
            vitaminE: est?.vitaminE100g.map { "\($0)mg" }
        )
    }

    func toProductJson() -> String? {
        var dict: [String: Any] = [:]
        dict["product_name"] = productName ?? ""
        dict["brands"] = brands ?? NSNull()
        dict["image_url"] = imageURL ?? NSNull()
        dict["ingredients_text"] = ingredientsText ?? ingredientsTextEn ?? NSNull()
        dict["ingredients_text_en"] = ingredientsText ?? ingredientsTextEn ?? NSNull()
        dict["nutriscore_grade"] = nutriscoreGrade ?? NSNull()
        dict["nutrition_data"] = "on"
        dict["nutrition_data_per"] = "100g"
        var nutrimentsDict: [String: Any] = [:]
        if let n = nutriments {
            nutrimentsDict["energy-kcal"] = n.energyKcal100g ?? 0
            nutrimentsDict["energy-kcal_100g"] = n.energyKcal100g ?? 0
            nutrimentsDict["energy-kcal_serving"] = n.energyKcalServing ?? 0
            nutrimentsDict["energy-kcal_unit"] = "kcal"
            nutrimentsDict["proteins"] = n.proteins100g ?? 0
            nutrimentsDict["proteins_100g"] = n.proteins100g ?? 0
            nutrimentsDict["proteins_unit"] = "g"
            nutrimentsDict["carbohydrates"] = n.carbohydrates100g ?? 0
            nutrimentsDict["carbohydrates_100g"] = n.carbohydrates100g ?? 0
            nutrimentsDict["carbohydrates_unit"] = "g"
            nutrimentsDict["fat"] = n.fat100g ?? 0
            nutrimentsDict["fat_100g"] = n.fat100g ?? 0
            nutrimentsDict["fat_unit"] = "g"
            nutrimentsDict["sugars"] = n.sugars100g ?? 0
            nutrimentsDict["fiber"] = n.fiber100g ?? 0
            nutrimentsDict["sodium"] = n.sodium100g ?? 0
            nutrimentsDict["cholesterol"] = n.cholesterol100g ?? 0
        }
        dict["nutriments"] = nutrimentsDict
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
}

struct Nutriments: Codable {
    let energyKcal100g: Double?
    let energyKcalServing: Double?
    let proteins100g: Double?
    let proteinsServing: Double?
    let fat100g: Double?
    let fatServing: Double?
    let carbohydrates100g: Double?
    let carbohydratesServing: Double?
    let sugars100g: Double?
    let sugarsServing: Double?
    let fiber100g: Double?
    let fiberServing: Double?
    let sodium100g: Double?
    let sodiumServing: Double?
    let cholesterol100g: Double?
    let cholesterolServing: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case energyKcalServing = "energy-kcal_serving"
        case proteins100g = "proteins_100g"
        case proteinsServing = "proteins_serving"
        case fat100g = "fat_100g"
        case fatServing = "fat_serving"
        case carbohydrates100g = "carbohydrates_100g"
        case carbohydratesServing = "carbohydrates_serving"
        case sugars100g = "sugars_100g"
        case sugarsServing = "sugars_serving"
        case fiber100g = "fiber_100g"
        case fiberServing = "fiber_serving"
        case sodium100g = "sodium_100g"
        case sodiumServing = "sodium_serving"
        case cholesterol100g = "cholesterol_100g"
        case cholesterolServing = "cholesterol_serving"
    }
}

struct NutrimentsEstimated: Codable {
    let vitaminA100g: Double?
    let vitaminB12100g: Double?
    let vitaminB6100g: Double?
    let vitaminB9100g: Double?
    let vitaminC100g: Double?
    let vitaminD100g: Double?
    let vitaminE100g: Double?

    enum CodingKeys: String, CodingKey {
        case vitaminA100g = "vitamin-a_100g"
        case vitaminB12100g = "vitamin-b12_100g"
        case vitaminB6100g = "vitamin-b6_100g"
        case vitaminB9100g = "vitamin-b9_100g"
        case vitaminC100g = "vitamin-c_100g"
        case vitaminD100g = "vitamin-d_100g"
        case vitaminE100g = "vitamin-e_100g"
    }
}

struct AnalysisResponse: Codable {
    let productName: String?
    let healthScore: Int?
    let riskLevel: String?
    let risks: [AnalysisRisk]?
    let dietConflicts: [AnalysisDietConflict]?
    let sources: [AnalysisSource]?
    let isFood: Bool?
    let productType: String?
    let verdict: String?
    let macros: AnalysisMacros?
    let alternatives: [AnalysisAlternative]?
    let scanImage: AnalysisScanImage?
    let productPhoto: AnalysisProductPhoto?
    let scanImageUrl: String?
    let imagePath: String?
    let dailyImpact: AnalysisDailyImpact?
    let userContextUsed: AnalysisUserContextUsed?

    enum CodingKeys: String, CodingKey {
        case healthScore = "health_score"
        case riskLevel = "risk_level"
        case dietConflicts = "diet_conflicts"
        case isFood = "is_food"
        case productType = "product_type"
        case productName = "product_name"
        case scanImage = "scan_image"
        case productPhoto = "product_photo"
        case scanImageUrl = "scan_image_url"
        case imagePath = "image_path"
        case dailyImpact = "daily_impact"
        case userContextUsed = "user_context_used"
        case risks, sources, verdict, macros, alternatives
    }
}

struct AnalysisMacros: Codable {
    let calories: Double?
    let proteins: Double?
    let carbs: Double?
    let fats: Double?
    let fat: Double?
    let sugar: Double?
    let fiber: Double?
    let sodium: Double?
    let cholesterol: Double?
    let vitaminA: Double?
    let vitaminB12: Double?
    let vitaminB6: Double?
    let vitaminB9: Double?
    let vitaminC: Double?
    let vitaminD: Double?
    let vitaminE: Double?
    enum CodingKeys: String, CodingKey {
        case calories, proteins, carbs, fats, fat, sugar, fiber, sodium, cholesterol
        case vitaminA = "vitamin_a"
        case vitaminB12 = "vitamin_b12"
        case vitaminB6 = "vitamin_b6"
        case vitaminB9 = "vitamin_b9"
        case vitaminC = "vitamin_c"
        case vitaminD = "vitamin_d"
        case vitaminE = "vitamin_e"
    }
    /// Resolved fat value (API sometimes returns "fat" sometimes "fats")
    var resolvedFat: Double? { fats ?? fat }
}

struct AnalysisRisk: Codable, Identifiable {
    var id: String { ingredient ?? UUID().uuidString }
    let ingredient: String?
    let reason: String?
    let severity: String?
    let sourceIndexes: [Int]?
    enum CodingKeys: String, CodingKey {
        case ingredient, reason, severity
        case sourceIndexes = "source_indexes"
    }
}

struct AnalysisDietConflict: Codable, Identifiable {
    var id: String { dietCode ?? UUID().uuidString }
    let dietCode: String?
    let reason: String?
    let severity: String?
    enum CodingKeys: String, CodingKey {
        case dietCode = "diet_code"
        case reason, severity
    }
}

struct AnalysisSource: Codable, Identifiable {
    var id: String { url ?? title ?? UUID().uuidString }
    let title: String?
    let url: String?
    let sourceType: String?
    enum CodingKeys: String, CodingKey {
        case title, url
        case sourceType = "source_type"
    }
}

struct AnalysisAlternative: Codable, Identifiable {
    var id: String { name ?? UUID().uuidString }
    let name: String?
    let reason: String?
    let kaspiLink: String?
    enum CodingKeys: String, CodingKey {
        case name, reason
        case kaspiLink = "kaspi_link"
    }
}

struct AnalysisScanImage: Codable {
    let bucket: String?
    let key: String?
    let contentType: String?
    let url: String?
    enum CodingKeys: String, CodingKey {
        case bucket, key, url
        case contentType = "content_type"
    }
}

struct AnalysisProductPhoto: Codable {
    let name: String?
    let imageUrl: String?
    let barcode: String?
    let brand: String?
    let source: String?
    enum CodingKeys: String, CodingKey {
        case name, barcode, brand, source
        case imageUrl = "image_url"
    }
}

struct AnalysisDailyImpact: Codable {
    let calories: AnalysisDailyImpactItem?
    let carbs: AnalysisDailyImpactItem?
    let fat: AnalysisDailyImpactItem?
    let fiber: AnalysisDailyImpactItem?
    let proteins: AnalysisDailyImpactItem?
    let sodium: AnalysisDailyImpactItem?
    let sugar: AnalysisDailyImpactItem?
    let vitaminA: AnalysisDailyImpactItem?
    let vitaminB12: AnalysisDailyImpactItem?
    let vitaminB6: AnalysisDailyImpactItem?
    let vitaminB9: AnalysisDailyImpactItem?
    let vitaminC: AnalysisDailyImpactItem?
    let vitaminD: AnalysisDailyImpactItem?
    let vitaminE: AnalysisDailyImpactItem?
    let water: AnalysisDailyImpactItem?
    enum CodingKeys: String, CodingKey {
        case calories, carbs, fat, fiber, proteins, sodium, sugar, water
        case vitaminA = "vitamin_a"; case vitaminB12 = "vitamin_b12"
        case vitaminB6 = "vitamin_b6"; case vitaminB9 = "vitamin_b9"
        case vitaminC = "vitamin_c"; case vitaminD = "vitamin_d"; case vitaminE = "vitamin_e"
    }
}

struct AnalysisDailyImpactItem: Codable {
    let amountInProduct: Double?
    let consumedToday: Double?
    let goalToday: Double?
    let afterThisProduct: Double?
    let remainingToGoal: Double?
    let status: String?
    let message: String?
    let unit: String?
    enum CodingKeys: String, CodingKey {
        case status, message, unit
        case amountInProduct = "amount_in_product"
        case consumedToday = "consumed_today"
        case goalToday = "goal_today"
        case afterThisProduct = "after_this_product"
        case remainingToGoal = "remaining_to_goal"
    }
}

struct AnalysisUserContextUsed: Codable {
    let hasUserInformation: Bool?
    let hasLegacyHealthInfo: Bool?
    enum CodingKeys: String, CodingKey {
        case hasUserInformation = "has_user_information"
        case hasLegacyHealthInfo = "has_legacy_health_info"
    }
}

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool { self?.isEmpty ?? true }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

import SwiftUI
