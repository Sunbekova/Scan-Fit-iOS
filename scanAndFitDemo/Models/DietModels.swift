import SwiftUI
import SwiftData

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
    var categoryName: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case uiType = "ui_type"
        case isSelected
        case maxLevels = "max_levels"
        case subOptions = "sub_options"
        case triggers
        case categoryName = "category_name"
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
