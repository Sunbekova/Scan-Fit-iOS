import SwiftUI

extension HomeView {
    func loadAndShowNutrients() {
        let day = trackerVM.selectedDayString
        Task {
            do {
                let resp = try await BackendUserService.shared.getCaloriesByDay(day: day)
                if resp.success {
                    await MainActor.run {
                        nutrientCaloriesData = resp.data
                        showNutrientSheet = true
                    }
                }
            } catch {
                await MainActor.run { showNutrientSheet = true }
            }
        }
    }
}

struct MacrosRow: View {
    @ObservedObject var trackerVM: TrackerViewModel
    
    var body: some View {
        HStack(spacing: 10) {
            MacroCard(
                title: "Proteins",
                imageName: "ic_proteins",
                value: "\(Int(trackerVM.totalProteins)) g",
                limit: "\(Int(trackerVM.proteinLimit)) g",
                progress: trackerVM.proteinProgress,
                color: .green
            )
            MacroCard(
                title: "Fat",
                imageName: "ic_fat",
                value: "\(Int(trackerVM.totalFat)) g",
                limit: "\(Int(trackerVM.fatLimit)) g",
                progress: trackerVM.fatProgress,
                color: .pink
            )
            MacroCard(
                title: "Carbs",
                imageName: "ic_carbs",
                value: "\(Int(trackerVM.totalCarbs)) g",
                limit: "\(Int(trackerVM.carbLimit)) g",
                progress: trackerVM.carbProgress,
                color: .orange
            )
        }
    }
}

struct MacroCard: View {
    let title: String
    let imageName: String
    let value: String
    let limit: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            Text(value).font(.system(size: 18, weight: .bold))
            ProgressView(value: progress).tint(color).scaleEffect(x: 1, y: 1.5)
            Text("/ \(limit)").font(.caption2).foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}
