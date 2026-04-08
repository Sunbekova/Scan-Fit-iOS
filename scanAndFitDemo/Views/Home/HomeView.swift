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
                Text("Hi, \(authVM.displayName) 👋")
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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Calories")
                    .font(.headline)
                Spacer()
                Text("\(trackerVM.totalCalories) / \(trackerVM.calorieLimit) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: trackerVM.calorieProgress)
                .tint(Color("AppGreen"))
                .scaleEffect(x: 1, y: 2.5, anchor: .center)

            HStack {
                VStack(alignment: .leading) {
                    Text("\(trackerVM.totalCalories)")
                        .font(.system(size: 24, weight: .bold))
                    Text("Consumed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(trackerVM.caloriesLeft)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color("AppGreen"))
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    // MARK: - Macros Row

    private var macrosRow: some View {
        HStack(spacing: 12) {
            MacroCard(title: "Protein", value: "\(Int(trackerVM.totalProteins))g",
                      limit: "\(trackerVM.proteinLimit)g", progress: trackerVM.proteinProgress, color: .blue)
            MacroCard(title: "Carbs", value: "\(Int(trackerVM.totalCarbs))g",
                      limit: "\(trackerVM.carbLimit)g", progress: trackerVM.carbProgress, color: .orange)
            MacroCard(title: "Fat", value: "\(Int(trackerVM.totalFat))g",
                      limit: "\(trackerVM.fatLimit)g", progress: trackerVM.fatProgress, color: .pink)
        }
    }

    // MARK: - Water

    private var waterSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Water Intake", systemImage: "drop.fill")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.2f / 1.75 L", trackerVM.waterLiters))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 6) {
                ForEach(0..<8) { idx in
                    Button {
                        if idx < trackerVM.waterGlasses { trackerVM.removeWater() }
                        else if idx == trackerVM.waterGlasses { trackerVM.addWater() }
                    } label: {
                        Image(systemName: idx < trackerVM.waterGlasses ? "drop.fill" : (idx == trackerVM.waterGlasses ? "drop.circle" : "drop"))
                            .font(.title2)
                            .foregroundColor(idx < trackerVM.waterGlasses ? Color.blue : .gray.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}

// MARK: - Macro Card

struct MacroCard: View {
    let title: String
    let value: String
    let limit: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 18, weight: .bold))
            ProgressView(value: progress)
                .tint(color)
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
