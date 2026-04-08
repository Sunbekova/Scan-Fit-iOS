import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteProductEntity.productName) private var favorites: [FavoriteProductEntity]
    @State private var selectedItem: FoodItem?

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(favorites) { fav in
                            FoodRowView(item: fav.toFoodItem(), showFavorite: true) {
                                removeFavorite(fav)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedItem = fav.toFoodItem() }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Clear All", role: .destructive) { deleteAll() }
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationDestination(item: $selectedItem) { item in
                ProductDetailView(foodItem: item)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            Text("No favorites yet")
                .font(.headline)
            Text("Tap the heart on any product to save it here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func removeFavorite(_ fav: FavoriteProductEntity) {
        modelContext.delete(fav)
        try? modelContext.save()
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(favorites[index]) }
        try? modelContext.save()
    }

    private func deleteAll() {
        favorites.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}
