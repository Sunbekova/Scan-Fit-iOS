import SwiftUI
import SwiftData

struct RecentView: View {
    @EnvironmentObject private var trackerVM: TrackerViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecentProductEntity.timestamp, order: .reverse) private var recents: [RecentProductEntity]
    @Query private var favorites: [FavoriteProductEntity]
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

    private var favoriteIDs: Set<String> { Set(favorites.map(\.id)) }

    private var filteredRecents: [RecentProductEntity] {
        var items = recents
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
                    } else if filteredRecents.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(filteredRecents) { recent in
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
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search recent products".localized)
            .navigationTitle("Recent".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All".localized, role: .destructive) { clearAll() }
                        .foregroundColor(.red).font(.subheadline)
                }
            }
            .navigationDestination(item: $selectedItem) { item in
                ProductDetailView(foodItem: item).environmentObject(trackerVM)
            }
            .onChange(of: recents) { _, newValue in
                if newValue.count > 50 {
                    let extra = newValue.suffix(from: 50)
                    extra.forEach { modelContext.delete($0) }
                    try? modelContext.save()
                }
            }
            .task { await syncFromBackend() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 60)).foregroundColor(.gray.opacity(0.4))
            Text("No recent products".localized).font(.headline)
            Text("Scan or search products to see them here.".localized)
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }

    private func syncFromBackend() async {
        isLoadingBackend = true
        defer { isLoadingBackend = false }
        guard let resp = try? await BackendUserService.shared.getUserHistory(),
              resp.success, let items = resp.data else { return }

        let decoder = JSONDecoder()
        for item in items {
            guard let data = item.productData.data(using: .utf8),
                  let foodItem = try? decoder.decode(FoodItem.self, from: data) else { continue }
            let existing = recents.first(where: { $0.id == foodItem.id || $0.productName == foodItem.title })
            if existing == nil {
                let entity = RecentProductEntity(from: foodItem)
                modelContext.insert(entity)
            }
        }
        try? modelContext.save()
    }

    private func toggleFavorite(_ recent: RecentProductEntity, isFavorite: Bool) {
        if isFavorite {
            if let fav = favorites.first(where: { $0.id == recent.id }) { modelContext.delete(fav) }
        } else {
            let fav = FavoriteProductEntity(from: recent.toFoodItem(isFavorite: true))
            modelContext.insert(fav)
        }
        try? modelContext.save()
    }

    private func clearAll() {
        recents.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}
