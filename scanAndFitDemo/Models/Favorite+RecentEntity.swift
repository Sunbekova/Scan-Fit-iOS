import SwiftUI
import SwiftData

@Model
final class FavoriteProductEntity {

    @Attribute(.unique) var id: String
    var productName: String
    var brand: String?
    var imageURL: String?
    var calories: String?
    var grade: String?
    var ingredients: String?
    var source: String?   // "scan" | "openfoodfacts"

    init(from item: FoodItem) {
        self.id = item.id
        self.productName = item.title
        self.brand = item.subtitle
        self.imageURL = item.imageURL
        self.calories = item.calories
        self.grade = item.grade
        self.ingredients = item.ingredients
        self.source = item.source
    }

    func toFoodItem() -> FoodItem {
        FoodItem(
            id: id, title: productName, subtitle: brand,
            imageURL: imageURL, calories: calories, grade: grade,
            isFavorite: true, ingredients: ingredients, source: source
        )
    }
}

@Model
final class RecentProductEntity {

    @Attribute(.unique) var id: String
    var productName: String
    var subtitle: String?
    var imageURL: String?
    var calories: String?
    var grade: String?
    var timestamp: Date
    var ingredients: String?
    var source: String?   // "scan" | "openfoodfacts"

    // Alias used in some views
    var title: String { productName }

    init(from item: FoodItem) {
        self.id = item.id
        self.productName = item.title
        self.subtitle = item.subtitle
        self.imageURL = item.imageURL
        self.calories = item.calories
        self.grade = item.grade
        self.timestamp = Date()
        self.ingredients = item.ingredients
        self.source = item.source
    }

    func toFoodItem(isFavorite: Bool = false) -> FoodItem {
        FoodItem(
            id: id, title: productName, subtitle: subtitle,
            imageURL: imageURL, calories: calories, grade: grade,
            isFavorite: isFavorite, ingredients: ingredients, source: source
        )
    }
}
