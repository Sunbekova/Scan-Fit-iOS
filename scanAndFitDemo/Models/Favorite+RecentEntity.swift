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

    init(from item: FoodItem) {
        self.id = item.id
        self.productName = item.title
        self.brand = item.subtitle
        self.imageURL = item.imageURL
        self.calories = item.calories
        self.grade = item.grade
        self.ingredients = item.ingredients
    }

    func toFoodItem() -> FoodItem {
        FoodItem(
            id: id,
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

    init(from item: FoodItem) {
        self.id = item.id
        self.title = item.title
        self.subtitle = item.subtitle
        self.imageURL = item.imageURL
        self.calories = item.calories
        self.grade = item.grade
        self.timestamp = Date()
        self.ingredients = item.ingredients
    }

    func toFoodItem(isFavorite: Bool = false) -> FoodItem {
        FoodItem(
            id: id,
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
