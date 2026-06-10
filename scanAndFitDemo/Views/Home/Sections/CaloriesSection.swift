import SwiftUI

struct CalorieCard: View {
    @ObservedObject var trackerVM: TrackerViewModel
    var onTap: () -> Void
    
    var body: some View {
        Button { onTap() } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").foregroundColor(.green)
                    Text("Calories".localized).font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.secondary).font(.caption)
                }
                
                Text("\(trackerVM.totalCalories) kcal")
                    .font(.system(size: 32, weight: .bold))

                Text(String(format: "%d kcal left".localized, trackerVM.caloriesLeft))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                ProgressView(value: trackerVM.calorieProgress)
                    .tint(Color("AppGreen"))
                    .scaleEffect(x: 1, y: 2.2)
                    .padding(.top, 6)
            }
            .padding(20)
            .background(Color(.systemGray6))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MacrosRow

struct MacrosRow: View {
    @ObservedObject var trackerVM: TrackerViewModel

    var body: some View {
        HStack(spacing: 10) {
            MacroCard(
                title: "Proteins".localized,
                value: "\(Int(trackerVM.totalProteins)) g",
                limit: "\(Int(trackerVM.proteinLimit)) g",
                progress: trackerVM.proteinProgress,
                color: .green
            )
            MacroCard(
                title: "Fat".localized,
                value: "\(Int(trackerVM.totalFat)) g",
                limit: "\(Int(trackerVM.fatLimit)) g",
                progress: trackerVM.fatProgress,
                color: .pink
            )
            MacroCard(
                title: "Carbs".localized,
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
    let value: String
    let limit: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
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
