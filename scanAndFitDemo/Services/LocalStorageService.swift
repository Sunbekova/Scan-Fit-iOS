import Foundation
import SwiftData

final class LocalStorageService {
    static func isFavorite(id: String, context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<FavoriteProductEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return (try? context.fetch(descriptor).isEmpty == false) ?? false
    }

    static func toggleFavorite(item: FoodItem, context: ModelContext) {
        let descriptor = FetchDescriptor<FavoriteProductEntity>(
            predicate: #Predicate { $0.id == item.id })
        if let existing = try? context.fetch(descriptor).first {context.delete(existing)
        } else {context.insert(FavoriteProductEntity(from: item))}
        save(context)
    }

    static func saveRecent(item: FoodItem, context: ModelContext) {
        let descriptor = FetchDescriptor<RecentProductEntity>(
            predicate: #Predicate { $0.id == item.id })
        if let existing = try? context.fetch(descriptor).first {existing.timestamp = Date()
        } else {context.insert(RecentProductEntity(from: item))}
        save(context)
    }

    private static func save(_ context: ModelContext) {
        do {try context.save()
        } catch {print("SwiftData save error:", error)}
    }
}
