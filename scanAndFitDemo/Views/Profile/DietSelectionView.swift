import SwiftUI

struct DietSelectionView: View {
    @EnvironmentObject private var authVM: BackendAuthViewModel
    @EnvironmentObject private var profileVM: UserProfileViewModel
    
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("Your Health Profile")
                        .font(.system(size: 26, weight: .bold))
                    Text("Please mark everything you have. This will help us make personalized recommendations when reviewing products.")
                        .font(.system(size: 14))
                        .foregroundColor(.primary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 24)

                if profileVM.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else {
                    VStack(spacing: 32) {
                        if !profileVM.healthConditions.isEmpty {
                            categorySection(
                                title: "Health Conditions",
                                items: profileVM.healthConditions
                            ) { item in
                                Task { await profileVM.toggleHealthCondition(item) }
                            }
                        }

                        if !profileVM.dietTypes.isEmpty {
                            categorySection(
                                title: "Diet Preferences",
                                items: profileVM.dietTypes
                            ) { item in
                                Task { await profileVM.toggleDietType(item) }
                            }
                        }

                        if !profileVM.dietaryPrefs.isEmpty {
                            categorySection(
                                title: "Dietary Preferences",
                                items: profileVM.dietaryPrefs
                            ) { item in
                                Task { await profileVM.toggleDietaryPreference(item) }
                            }
                        }

                        if !profileVM.diseases.isEmpty {
                            categorySection(
                                title: "Specify stage / type",
                                items: profileVM.diseases,
                                showSearch: true
                            ) { item in
                                let levelId = item.diseaseLevel?.id ?? 1
                                Task { await profileVM.toggleDisease(item, levelId: levelId, isActive: !item.isActive) }
                            }
                        }

                        if profileVM.dietTypes.isEmpty &&
                            profileVM.healthConditions.isEmpty &&
                            profileVM.diseases.isEmpty {
                            emptyStateView
                        }
                    }
                }

                if let error = profileVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 20)
        }
        .safeAreaInset(edge: .bottom) {
            // Floating bottom layout matching the PNG
            VStack(spacing: 16) {
                Button(action: {
                    authVM.markProfileCompleted()
                }) {
                    Text("Finish Setup")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("AppGreen"))
                        .cornerRadius(24)
                }
                
                Button(action: {
                    authVM.markProfileCompleted()
                }) {
                    Text("Not Now")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.gray.opacity(0.6))
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.white.opacity(0), .white.opacity(0.9), .white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await profileVM.loadAll()
        }
    }


    @ViewBuilder
    private func categorySection<T: Identifiable & Nameable & Activeable>(
        title: String,
        items: [T],
        showSearch: Bool = false,
        onTap: @escaping (T) -> Void
    ) -> some View {

        VStack(alignment: .leading, spacing: 16) {
            // Title Header
            HStack {
                if showSearch {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 18, weight: .bold))
            }
            .padding(.horizontal, 4)

            // Dynamic Search Bar for specific sub-categories
            if showSearch {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .font(.system(size: 18, weight: .semibold))
                    TextField("Find allergy or disease...", text: $searchText)
                        .font(.system(size: 15))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.bottom, 4)
            }

            // Chips Grid
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                let filteredItems = (showSearch && !searchText.isEmpty)
                    ? items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                    : items
                
                ForEach(filteredItems) { item in
                    DietChipView(
                        title: item.name,
                        isSelected: item.isActive
                    ) {
                        onTap(item)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 40))
                .foregroundColor(Color.blue.opacity(0.5))
            Text("No categories found")
                .foregroundColor(.secondary)
            Text("Tap Continue to proceed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 32)
    }
}


protocol Nameable { var name: String { get } }
protocol Activeable { var isActive: Bool { get } }


struct DietChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color("AppGreen") : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(24)
        }
    }
}
