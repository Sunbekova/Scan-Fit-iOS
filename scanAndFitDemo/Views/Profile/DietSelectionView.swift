import SwiftUI

struct DietSelectionView: View {
    @EnvironmentObject private var authVM: BackendAuthViewModel
    @EnvironmentObject private var profileVM: UserProfileViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Your Health Profile")
                        .font(.system(size: 26, weight: .bold))
                    Text("Select all that apply")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)

                if profileVM.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else {

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

                    if !profileVM.healthConditions.isEmpty {
                        categorySection(
                            title: "Health Conditions",
                            items: profileVM.healthConditions
                        ) { item in
                            Task { await profileVM.toggleHealthCondition(item) }
                        }
                    }

                    if !profileVM.diseases.isEmpty {
                        categorySection(
                            title: "Diseases / Allergies",
                            items: profileVM.diseases
                        ) { item in
                            let levelId = item.diseaseLevel?.id ?? 1
                            Task { await profileVM.toggleDisease(item, levelId: levelId) }
                        }
                    }

                    if profileVM.dietTypes.isEmpty &&
                        profileVM.healthConditions.isEmpty &&
                        profileVM.diseases.isEmpty {

                        emptyStateView
                    }
                }

                if let error = profileVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                SFPrimaryButton(title: "Finish Setup") {
                    authVM.markProfileCompleted()
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
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
        onTap: @escaping (T) -> Void
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            Text(title)
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(items) { item in
                    DietChipView(
                        title: item.name,
                        isSelected: item.isActive
                    ) {
                        onTap(item)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 40))
                .foregroundColor(Color("AppGreen").opacity(0.5))
            Text("No categories found")
                .foregroundColor(.secondary)
            Text("Tap Finish to continue")
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
