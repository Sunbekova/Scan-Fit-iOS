import SwiftUI

struct DietSelectionView: View {
    @EnvironmentObject private var authVM: BackendAuthViewModel
    @State private var selectedItems: Set<String> = []
    @State private var categories: [HealthCategory] = []

    private let userDefaults = UserDefaults.standard

    private let builtInCategories: [HealthCategory] = [
        HealthCategory(
            id: "diet",
            categoryName: "Diet Preferences",
            items: [
                DietItem(id: "vegan", name: "Vegan", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
                DietItem(id: "vegetarian", name: "Vegetarian", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
                DietItem(id: "gluten_free", name: "Gluten-Free", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
                DietItem(id: "lactose_free", name: "Lactose-Free", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
                DietItem(id: "keto", name: "Keto", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
                DietItem(id: "halal", name: "Halal", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
            ]
        ),
        HealthCategory(
            id: "conditions",
            categoryName: "Health Conditions",
            items: [
                DietItem(id: "diabetes", name: "Diabetes", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
                DietItem(id: "hypertension", name: "Hypertension", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
                DietItem(id: "heart_disease", name: "Heart Disease", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
                DietItem(id: "celiac", name: "Celiac Disease", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
                DietItem(id: "ibs", name: "IBS", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
            ]
        ),
        HealthCategory(
            id: "allergies",
            categoryName: "Allergies",
            items: [
                DietItem(id: "nuts", name: "Tree Nuts", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
                DietItem(id: "peanuts", name: "Peanuts", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
                DietItem(id: "shellfish", name: "Shellfish", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
                DietItem(id: "soy", name: "Soy", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
                DietItem(id: "eggs", name: "Eggs", uiType: "toggle", maxLevels: nil, subOptions: nil, triggers: nil),
            ]
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Your Health Profile")
                        .font(.system(size: 26, weight: .bold))
                    Text("Select all that apply")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.top, 24)

                ForEach(builtInCategories) { category in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(category.categoryName)
                            .font(.headline)
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(category.items) { item in
                                DietChipView(
                                    title: item.name,
                                    isSelected: selectedItems.contains(item.id)
                                ) {
                                    if selectedItems.contains(item.id) {
                                        selectedItems.remove(item.id)
                                    } else {
                                        selectedItems.insert(item.id)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }

                SFPrimaryButton(title: "Finish Setup") { saveAndFinish() }
                    .padding(.top, 8)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden(true)
    }

    private func saveAndFinish() {
        let selectedNames = builtInCategories
            .flatMap(\.items)
            .filter { selectedItems.contains($0.id) }
            .map(\.name)
        userDefaults.set(selectedNames, forKey: "user_diseases")
        authVM.markProfileCompleted()
    }
}

struct DietChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : Color("AppGreen"))
                Text(title)
                    .font(.subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color("AppGreen") : Color.white)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("AppGreen"), lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}
