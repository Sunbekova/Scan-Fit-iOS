import SwiftUI
import SwiftData

struct RecentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecentProductEntity.timestamp, order: .reverse) private var recents: [RecentProductEntity]
    @Query private var favorites: [FavoriteProductEntity]
    @State private var selectedItem: FoodItem?

    private var favoriteIDs: Set<String> {
        Set(favorites.map(\.id))
    }

    var body: some View {
        NavigationStack {
            Group {
                if recents.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(recents) { recent in
                            let isFav = favoriteIDs.contains(recent.id)
                            FoodRowView(item: recent.toFoodItem(isFavorite: isFav), showFavorite: true) {
                                toggleFavorite(recent, isFavorite: isFav)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedItem = recent.toFoodItem(isFavorite: isFav) }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Clear All", role: .destructive) { clearAll() }
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Recent")
            .navigationDestination(item: $selectedItem) { item in
                ProductDetailView(foodItem: item)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            Text("No recent products")
                .font(.headline)
            Text("Products you view will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func toggleFavorite(_ recent: RecentProductEntity, isFavorite: Bool) {
        if isFavorite {
            if let fav = favorites.first(where: { $0.id == recent.id }) {
                modelContext.delete(fav)
            }
        } else {
            let foodItem = recent.toFoodItem(isFavorite: true)
            let fav = FavoriteProductEntity(from: foodItem)
            modelContext.insert(fav)
        }
        try? modelContext.save()
    }

    private func clearAll() {
        recents.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}
