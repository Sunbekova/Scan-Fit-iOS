import SwiftUI

struct CalorieCard: View {
    @ObservedObject var trackerVM: TrackerViewModel
    var onTap: () -> Void
    
    var body: some View {
        Button { onTap() } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").foregroundColor(.green)
                    Text("Calories").font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.secondary).font(.caption)
                }
                
                Text("\(trackerVM.totalCalories) kcal")
                    .font(.system(size: 32, weight: .bold))
                
                Text("\(trackerVM.caloriesLeft) kcal left")
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

