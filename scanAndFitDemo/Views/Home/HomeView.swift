import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authVM: BackendAuthViewModel
    @EnvironmentObject var trackerVM: TrackerViewModel
    @State private var showProfile = false
    @State private var showDatePicker = false
    @State var showNutrientSheet = false
    @State var nutrientCaloriesData: BackendUserCaloriesData? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    CalendarSection(trackerVM: trackerVM)
                    CalorieCard(trackerVM: trackerVM){loadAndShowNutrients()}
                    MacrosRow(trackerVM: trackerVM)
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

}
