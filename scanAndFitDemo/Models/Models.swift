import Foundation
import SwiftData

// MARK: - Food Item (in-memory domain model)

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

    init(
        id: String = UUID().uuidString, //if x barcode
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
        ingredients: String? = nil
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
    let ingredientsText: String?
    let ingredientsTextEn: String?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case imageURL = "image_url"
        case nutriscoreGrade = "nutriscore_grade"
        case nutriments
        case ingredientsText = "ingredients_text"
        case ingredientsTextEn = "ingredients_text_en"
    }
}

extension APIProduct {
    func toFoodItem() -> FoodItem {

        let nutris = nutriments

        let kcal = nutris?.energyKcalServing ?? nutris?.energyKcal100g ?? 0

        return FoodItem(
            id: code ?? UUID().uuidString,

            title: productName ?? "Unknown Product",
            subtitle: brands,
            imageURL: imageURL,

            calories: "\(Int(kcal)) kcal",
            grade: nutriscoreGrade?.uppercased() ?? "B",

            proteins: "\(nutris?.proteinsServing ?? nutris?.proteins100g ?? 0)g",
            fat: "\(nutris?.fatServing ?? nutris?.fat100g ?? 0)g",
            carbs: "\(nutris?.carbohydratesServing ?? nutris?.carbohydrates100g ?? 0)g",
            description: "",

            cholesterol: "\(nutris?.cholesterolServing ?? nutris?.cholesterol100g ?? 0)mg",
            sodium: "\(nutris?.sodiumServing ?? nutris?.sodium100g ?? 0)mg",
            sugars: "\(nutris?.sugarsServing ?? nutris?.sugars100g ?? 0)g",
            fiber: "\(nutris?.fiberServing ?? nutris?.fiber100g ?? 0)g",

            ingredients: ingredientsText ?? ingredientsTextEn
        )
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

// MARK: - AI Analysis Models

struct AnalysisResponse: Codable {
    let healthScore: Int?
    let risks: [String]?
    let isFood: Bool?
    let productType: String?
    let verdict: String?
    let macros: AnalysisMacros?

    enum CodingKeys: String, CodingKey {
        case healthScore = "health_score"
        case risks
        case isFood = "is_food"
        case productType = "product_type"
        case verdict
        case macros
    }
}

struct AnalysisMacros: Codable {
    let calories: Double?
    let proteins: Double?
    let carbs: Double?
    let fats: Double?
}

