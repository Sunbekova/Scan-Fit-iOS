import SwiftUI
import SwiftData

struct FavoritesView: View {
    @EnvironmentObject private var trackerVM: TrackerViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteProductEntity.productName) private var favorites: [FavoriteProductEntity]
    @State private var selectedItem: FoodItem?
    @State private var searchText = ""
    @State private var selectedFilter: SourceFilter = .all
    @State private var isLoadingBackend = false

    enum SourceFilter: String, CaseIterable {
        case all = "All"
        case scan = "Scan"
        case openfoodfacts = "Search"

        var label: String { rawValue.localized }
    }

    private var filteredFavorites: [FavoriteProductEntity] {
        var items = favorites
        if selectedFilter != .all {
            items = items.filter { ($0.source ?? "") == selectedFilter.rawValue.lowercased() }
        }
        if !searchText.isEmpty {
            items = items.filter { $0.productName.localizedCaseInsensitiveContains(searchText) }
        }
        return items
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SourceFilter.allCases, id: \.self) { filter in
                            Button(filter.label) { selectedFilter = filter }
                                .font(.caption).fontWeight(.medium)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(selectedFilter == filter ? Color("AppGreen") : Color(.systemGray5))
                                .foregroundColor(selectedFilter == filter ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                }

                Group {
                    if isLoadingBackend {
                        ProgressView().padding(.top, 40)
                    } else if filteredFavorites.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(filteredFavorites) { fav in
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
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search favorites".localized)
            .navigationTitle("Favorites".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All".localized, role: .destructive) { deleteAll() }
                        .foregroundColor(.red).font(.subheadline)
                }
            }
            .navigationDestination(item: $selectedItem) { item in
                ProductDetailView(foodItem: item).environmentObject(trackerVM)
            }
            .task { await syncFromBackend() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60)).foregroundColor(.gray.opacity(0.4))
            Text("No favorites yet".localized).font(.headline)
            Text("Tap the heart on any product to save it here.".localized)
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }

    private func syncFromBackend() async {
        isLoadingBackend = true
        defer { isLoadingBackend = false }
        guard let resp = try? await BackendUserService.shared.getUserLikes(),
              resp.success, let items = resp.data else { return }
        let decoder = JSONDecoder()
        for item in items {
            guard let data = item.productData.data(using: .utf8),
                  let foodItem = try? decoder.decode(FoodItem.self, from: data) else { continue }
            let alreadySaved = favorites.contains(where: { $0.id == foodItem.id })
            if !alreadySaved {
                let entity = FavoriteProductEntity(from: foodItem)
                modelContext.insert(entity)
            }
        }
        try? modelContext.save()
    }

    private func removeFavorite(_ fav: FavoriteProductEntity) {
        modelContext.delete(fav); try? modelContext.save()
    }

    private func deleteItems(at offsets: IndexSet) {
        offsets.map { filteredFavorites[$0] }.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }

    private func deleteAll() {
        favorites.forEach { modelContext.delete($0) }; try? modelContext.save()
    }
}
