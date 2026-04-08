import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var trackerVM: TrackerViewModel
    @State private var showProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    // Weekly calendar
                    calendarSection
                    // Calories card
                    calorieCard
                    // Macros row
                    macrosRow
                    // Water tracker
                    waterSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showProfile) { UserProfileView() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hi, \(authVM.displayName)")
                    .font(.system(size: 22, weight: .bold))
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button { showProfile = true } label: {
                Circle()
                    .fill(Color("AppGreen").opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(authVM.displayName.prefix(1)).uppercased())
                            .font(.headline)
                            .foregroundColor(Color("AppGreen"))
                    )
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Calendar

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                ForEach(trackerVM.weekDays(for: trackerVM.selectedDate), id: \.self) { day in
                    let isSelected = trackerVM.isSameDay(day, trackerVM.selectedDate)
                    VStack(spacing: 4) {
                        Text(day.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.system(size: 11))
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSelected ? Color("AppGreen") : Color(.systemGray6))
                    .foregroundColor(isSelected ? .white : .primary)
                    .cornerRadius(10)
                    .onTapGesture { trackerVM.selectedDate = day }
                }
            }
        }
    }

    // MARK: - Calorie Card

    private var calorieCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.green)

                Text("Calories")
                    .font(.headline)
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

    // MARK: - Macros Row

    private var macrosRow: some View {
        HStack(spacing: 10) {
            MacroCard(
                title: "Proteins",
                imageName: "ic_proteins", // Matches @drawable/ic_proteins
                value: "\(Int(trackerVM.totalProteins)) g",
                limit: "\(trackerVM.proteinLimit) g",
                progress: trackerVM.proteinProgress,
                color: .green
            )

            MacroCard(
                title: "Fat",
                imageName: "ic_fat",
                value: "\(Int(trackerVM.totalFat)) g",
                limit: "\(trackerVM.fatLimit) g",
                progress: trackerVM.fatProgress,
                color: .pink
            )

            MacroCard(
                title: "Carbs",
                imageName: "ic_carbs",
                value: "\(Int(trackerVM.totalCarbs)) g",
                limit: "\(trackerVM.carbLimit) g",
                progress: trackerVM.carbProgress,
                color: .orange
            )
        }
    }

    // MARK: - Water

    private var waterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Left Side: Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Water balance")
                        .font(.headline)
                    
                    Text("\(trackerVM.waterLiters, specifier: "%.2f")L")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("Goal 1.75 L")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(AppImages.homeWaterImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 100)
            }

            HStack {
                ForEach(0..<trackerVM.maxWaterGlasses, id: \.self) { i in
                    Button {
                        if i < trackerVM.waterGlasses {
                            trackerVM.removeWater()
                        } else if i == trackerVM.waterGlasses {
                            trackerVM.addWater()
                        }
                    } label: {
                        Image(systemName: i < trackerVM.waterGlasses ? "drop.fill" : "drop")
                            .font(.system(size: 20))
                            .foregroundColor(i < trackerVM.waterGlasses ? .blue : .gray.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 10)
        }
        .padding(24)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(20)
    }
}

// MARK: - Macro Card

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
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
            
            ProgressView(value: progress)
                .tint(color)
                .scaleEffect(x: 1, y: 1.5)
            
            Text("/ \(limit)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}
