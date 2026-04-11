import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authVM: BackendAuthViewModel
    @EnvironmentObject private var trackerVM: TrackerViewModel
    @State private var showProfile = false
    @State private var showDatePicker = false
    @State private var showNutrientSheet = false
    @State private var nutrientCaloriesData: BackendUserCaloriesData? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    calendarSection
                    calorieCard
                    macrosRow
                    waterSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showProfile) { UserProfileView() }
            .sheet(isPresented: $showNutrientSheet) {
                NutrientDetailSheet(data: nutrientCaloriesData, day: trackerVM.selectedDayString)
            }
            .onAppear { trackerVM.loadForDate(trackerVM.selectedDate) }
            .onChange(of: trackerVM.selectedDate) { newDate in
                trackerVM.loadForDate(newDate)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hi, \(authVM.displayName)")
                    .font(.system(size: 22, weight: .bold))
                Button { showDatePicker = true } label: {
                    Text(trackerVM.selectedDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
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
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selectedDate: $trackerVM.selectedDate, isPresented: $showDatePicker)
        }
    }

    // MARK: - Calendar'

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

    // MARK: - macros

    private var calorieCard: some View {
        Button { loadAndShowNutrients() } label: {
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

    private var macrosRow: some View {
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

    // MARK: - su

    private var waterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Water balance").font(.headline)
                    Text(String(format: "%.2f L", trackerVM.waterLiters))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.blue)
                    Text(String(format: "Goal %.2f L", trackerVM.waterGoalLiters))
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

    // MARK: - adam jegeni

    private func loadAndShowNutrients() {
        let day = trackerVM.selectedDayString
        Task {
            do {
                let resp = try await BackendUserService.shared.getCaloriesByDay(day: day)
                if resp.success {
                    nutrientCaloriesData = resp.data
                }
            } catch {}
            showNutrientSheet = true
        }
    }
}

// MARK: - Date tan'dau

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            DatePicker("Select date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Pick Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { isPresented = false }
                    }
                }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - macros koru

struct NutrientDetailSheet: View {
    let data: BackendUserCaloriesData?
    let day: String
    @Environment(\.dismiss) private var dismiss

    private var isVip: Bool { TokenManager.shared.userRole == "vip" }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Basic Nutrients") {
                    nutrientRow("Calories", consumed: data?.daily?.calories.map { Double($0) }, goal: data?.calories.map { Double($0) }, unit: "kcal")
                    nutrientRow("Carbs", consumed: data?.daily?.carbs, goal: data?.carbs, unit: "g")
                    nutrientRow("Protein", consumed: data?.daily?.proteins, goal: data?.proteins, unit: "g")
                    nutrientRow("Fats", consumed: data?.daily?.fat, goal: data?.fat, unit: "g")
                }

                Section("Premium Nutrients") {
                    premiumNutrientRow("Sodium", consumed: data?.daily?.sodium, goal: data?.sodium, unit: "mg")
                    premiumNutrientRow("Fiber", consumed: data?.daily?.fiber, goal: data?.fiber, unit: "g")
                    premiumNutrientRow("Sugar", consumed: data?.daily?.sugar, goal: data?.sugar, unit: "g")
                    premiumNutrientRow("Cholesterol", consumed: data?.daily?.cholesterol, goal: data?.cholesterol, unit: "mg")
                    premiumNutrientRow("Vitamin A", consumed: data?.daily?.vitaminA, goal: data?.vitaminA, unit: "mcg")
                    premiumNutrientRow("Vitamin B12", consumed: data?.daily?.vitaminB12, goal: data?.vitaminB12, unit: "mcg")
                    premiumNutrientRow("Vitamin B6", consumed: data?.daily?.vitaminB6, goal: data?.vitaminB6, unit: "mg")
                    premiumNutrientRow("Vitamin C", consumed: data?.daily?.vitaminC, goal: data?.vitaminC, unit: "mg")
                    premiumNutrientRow("Vitamin D", consumed: data?.daily?.vitaminD, goal: data?.vitaminD, unit: "mcg")
                    premiumNutrientRow("Vitamin E", consumed: data?.daily?.vitaminE, goal: data?.vitaminE, unit: "mg")
                }
            }
            .navigationTitle("Nutrients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func nutrientRow(_ name: String, consumed: Double?, goal: Double?, unit: String) -> some View {
        HStack {
            Text(name).font(.body)
            Spacer()
            Text(formatPair(consumed, goal, unit))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func premiumNutrientRow(_ name: String, consumed: Double?, goal: Double?, unit: String) -> some View {
        HStack {
            Text(name).font(.body).opacity(isVip ? 1 : 0.6)
            Spacer()
            if isVip {
                Text(formatPair(consumed, goal, unit))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("ScanFit Pro")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
            }
        }
    }

    private func formatPair(_ consumed: Double?, _ goal: Double?, _ unit: String) -> String {
        let c = formatAmount(consumed ?? 0)
        let g = formatAmount(goal ?? 0)
        return "\(c) / \(g) \(unit)"
    }

    private func formatAmount(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }
}

// MARK: - Macros

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
