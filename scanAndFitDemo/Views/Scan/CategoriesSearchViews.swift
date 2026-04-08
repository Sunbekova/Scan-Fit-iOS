import SwiftUI

// MARK: - Categories View

struct CategoriesView: View {
    let categories = [
        ("Fruits & Vegetables", "leaf.fill", "en:fruits-and-vegetables"),
        ("Dairy", "cup.and.saucer.fill", "en:dairy"),
        ("Beverages", "waterbottle.fill", "en:beverages"),
        ("Snacks", "popcorn.fill", "en:snacks"),
        ("Cereals", "fork.knife", "en:cereals"),
        ("Meat & Fish", "fish.fill", "en:meats"),
        ("Bread", "birthday.cake.fill", "en:bread"),
        ("Baby Food", "figure.child", "en:baby-foods"),
        ("Sauces", "drop.fill", "en:sauces"),
        ("Frozen", "snowflake", "en:frozen-foods"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(categories, id: \.0) { cat in
                        NavigationLink(destination: ProductListView(category: cat.2, title: cat.0)) {
                            CategoryCard(name: cat.0, icon: cat.1)
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Browse")
        }
    }
}

struct CategoryCard: View {
    let name: String
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(Color("AppGreen"))
                .frame(height: 40)
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

// MARK: - Product List View

struct ProductListView: View {
    let category: String
    let title: String

    @State private var products: [FoodItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedItem: FoodItem?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading products...")
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash").font(.system(size: 40)).foregroundColor(.gray)
                    Text(error).foregroundColor(.secondary).multilineTextAlignment(.center)
                    Button("Retry") { Task { await loadProducts() } }
                        .foregroundColor(Color("AppGreen"))
                }
                .padding()
            } else {
                List(products) { item in
                    FoodRowView(item: item, showFavorite: false, onFavoriteToggle: nil)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedItem = item }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(title)
        .navigationDestination(item: $selectedItem) { item in
            ProductDetailView(foodItem: item)
        }
        .task { await loadProducts() }
    }

    private func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            let raw = try await NetworkService.shared.getProductsByCategory(category: category)
            products = raw.map { $0.toFoodItem() }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Search View

struct SearchView: View {
    @State private var query = ""
    @State private var results: [FoodItem] = []
    @State private var isLoading = false
    @State private var hasSearched = false
    @State private var selectedItem: FoodItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search products...", text: $query)
                        .submitLabel(.search)
                        .onSubmit { Task { await search() } }
                    if !query.isEmpty {
                        Button { query = ""; results = []; hasSearched = false } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()

                if isLoading {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if hasSearched && results.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").font(.system(size: 40)).foregroundColor(.gray)
                        Text("No results found").font(.headline)
                        Text("Try a different search term").font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(results) { item in
                        FoodRowView(item: item, showFavorite: false, onFavoriteToggle: nil)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedItem = item }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .navigationDestination(item: $selectedItem) { item in
                ProductDetailView(foodItem: item)
            }
        }
    }

    private func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        hasSearched = true
        do {
            let raw = try await NetworkService.shared.searchProducts(query: query)
            results = raw.map { $0.toFoodItem() }
        } catch {
            results = []
        }
        isLoading = false
    }
}
