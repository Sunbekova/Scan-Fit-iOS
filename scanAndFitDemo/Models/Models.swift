import Foundation
import SwiftData

// MARK: - Food Item (in-memory domain model)

struct FoodItem: Identifiable, Codable, Hashable {
    var id: String { title }
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

    func toFoodItem() -> FoodItem {
        let cal = nutriments?.energyKcal100g.map { "\(Int($0)) kcal" } ?? "N/A"
        let prot = nutriments?.proteins100g.map { String(format: "%.1fg", $0) } ?? "0g"
        let fatStr = nutriments?.fat100g.map { String(format: "%.1fg", $0) } ?? "0g"
        let carbStr = nutriments?.carbohydrates100g.map { String(format: "%.1fg", $0) } ?? "0g"
        let sugarStr = nutriments?.sugars100g.map { String(format: "%.1fg", $0) } ?? "0g"
        let fiberStr = nutriments?.fiber100g.map { String(format: "%.1fg", $0) } ?? "0g"
        let sodiumStr = nutriments?.sodium100g.map { String(format: "%.3fg", $0) } ?? "0g"

        return FoodItem(
            title: productName ?? "Unknown Product",
            subtitle: brands,
            imageURL: imageURL,
            calories: cal,
            grade: nutriscoreGrade?.uppercased() ?? "B",
            proteins: prot,
            fat: fatStr,
            carbs: carbStr,
            sugars: sugarStr,
            fiber: fiberStr,
            sodium: sodiumStr,
            ingredients: ingredientsTextEn ?? ingredientsText
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

// MARK: - SwiftData Persistence Entities

@Model
final class FavoriteProductEntity {
    @Attribute(.unique) var id: String
    var productName: String
    var brand: String?
    var imageURL: String?
    var calories: String?
    var grade: String?
    var ingredients: String?

    init(id: String, productName: String, brand: String?, imageURL: String?, calories: String?, grade: String?, ingredients: String?) {
        self.id = id
        self.productName = productName
        self.brand = brand
        self.imageURL = imageURL
        self.calories = calories
        self.grade = grade
        self.ingredients = ingredients
    }

    func toFoodItem() -> FoodItem {
        FoodItem(
            title: productName,
            subtitle: brand,
            imageURL: imageURL,
            calories: calories,
            grade: grade,
            isFavorite: true,
            ingredients: ingredients
        )
    }
}

@Model
final class RecentProductEntity {
    @Attribute(.unique) var id: String
    var title: String
    var subtitle: String?
    var imageURL: String?
    var calories: String?
    var grade: String?
    var timestamp: Date
    var ingredients: String?

    init(id: String, title: String, subtitle: String?, imageURL: String?, calories: String?, grade: String?, ingredients: String?) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
        self.calories = calories
        self.grade = grade
        self.timestamp = Date()
        self.ingredients = ingredients
    }

    func toFoodItem(isFavorite: Bool = false) -> FoodItem {
        FoodItem(
            title: title,
            subtitle: subtitle,
            imageURL: imageURL,
            calories: calories,
            grade: grade,
            isFavorite: isFavorite,
            ingredients: ingredients
        )
    }
}

// MARK: - Health/Diet Models

struct HealthData: Codable {
    let categories: [HealthCategory]
}

struct HealthCategory: Codable, Identifiable {
    let id: String
    let categoryName: String
    let items: [DietItem]

    enum CodingKeys: String, CodingKey {
        case id = "category_id"
        case categoryName = "category_name"
        case items
    }
}

struct DietItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let uiType: String
    var isSelected: Bool = false
    let maxLevels: Int?
    let subOptions: [SubOption]?
    let triggers: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name
        case uiType = "ui_type"
        case isSelected, maxLevels = "max_levels"
        case subOptions = "sub_options"
        case triggers
    }
}

struct SubOption: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let uiType: String?
    let triggers: [String]?
    let maxLevels: Int?

    enum CodingKeys: String, CodingKey {
        case id, name
        case uiType = "ui_type"
        case triggers
        case maxLevels = "max_levels"
    }
}

// MARK: - Auth State

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case profileIncomplete
    case authenticated
}
