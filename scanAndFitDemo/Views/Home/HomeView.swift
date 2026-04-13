import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authVM: BackendAuthViewModel
    @EnvironmentObject var trackerVM: TrackerViewModel
    @State private var showProfile = false
    @State private var showDatePicker = false
    @State var showNutrientSheet = false
    @State var nutrientCaloriesData: BackendUserCaloriesData? = nil
    @State private var showProPage = false
    @State private var showHistory = false
    @State private var userPhotoURL: String? = nil
    @State private var isVip = TokenManager.shared.isVip

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    if !isVip { proBanner }
                    CalendarSection(trackerVM: trackerVM)
                    CalorieCard(trackerVM: trackerVM) { loadAndShowNutrients() }
                    MacrosRow(trackerVM: trackerVM)
                    waterSection
                    historyButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showProfile) {
                UserProfileView().environmentObject(authVM)
            }
            .navigationDestination(isPresented: $showProPage) {
                ProSubscriptionView()
            }
            .navigationDestination(isPresented: $showHistory) {
                ConsumptionHistoryView(selectedDate: trackerVM.selectedDate)
            }
            .sheet(isPresented: $showNutrientSheet) {
                NutrientDetailSheet(
                    data: nutrientCaloriesData,
                    day: trackerVM.selectedDayString,
                    onShowHistory: { showNutrientSheet = false; showHistory = true }
                )
            }
            .onAppear {
                trackerVM.loadForDate(trackerVM.selectedDate)
                isVip = TokenManager.shared.isVip
                Task { await loadUserHeader() }
            }
            .onChange(of: trackerVM.selectedDate) { _, newDate in
                trackerVM.loadForDate(newDate)
            }
        }
    }

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
                Group {
                    if let photoURL = userPhotoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                                    .frame(width: 44, height: 44).clipShape(Circle())
                            default:
                                avatarInitialCircle
                            }
                        }
                    } else {
                        avatarInitialCircle
                    }
                }
            }
        }
        .padding(.top, 12)
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: $trackerVM.selectedDate,
                isPresented: $showDatePicker,
                minDate: trackerVM.firstAvailableDate
            )
        }
    }

    private var avatarInitialCircle: some View {
        Circle()
            .fill(Color("AppGreen").opacity(0.15))
            .frame(width: 44, height: 44)
            .overlay(
                Text(String(authVM.displayName.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundColor(Color("AppGreen"))
            )
    }

    private var proBanner: some View {
        HStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#FBBF24"))
            VStack(alignment: .leading, spacing: 2) {
                Text("Upgrade to ScanFit Pro")
                    .font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                Text("Unlimited AI scans & advanced tracking")
                    .font(.caption).foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            Button { showProPage = true } label: {
                Text("Get Pro")
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color(hex: "#17A34A")).cornerRadius(20)
            }
        }
        .padding(16)
        .background(
            LinearGradient(colors: [Color(hex: "#0F172A"), Color(hex: "#1E3A5F")],
                           startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(16)
    }

    private var waterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Water balance").font(.headline)
                    Text(String(format: "%.2f L", trackerVM.waterLiters))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.blue)
                    Text(String(format: "Goal %.2f L", trackerVM.waterGoalLiters))
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                Image((AppImages.homeWaterImage))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 100)
            }

            let maxGlasses = trackerVM.maxWaterGlasses
            let safeCount  = trackerVM.waterGlasses.clamped(to: 0...maxGlasses)

            HStack(spacing: 4) {
                ForEach(0..<maxGlasses, id: \.self) { i in
                    Button {
                        trackerVM.tapWaterGlass(at: i)
                    } label: {
                        waterGlassIcon(index: i, safeCount: safeCount)
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!trackerVM.isTodaySelected || trackerVM.isWaterUpdating)
                }
            }
            .padding(.top, 10)
            .opacity(trackerVM.isWaterUpdating ? 0.45 : (trackerVM.isTodaySelected ? 1.0 : 0.6))
            waterHintText
        }
        .padding(24)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(20)
    }

    @ViewBuilder
    private func waterGlassIcon(index: Int, safeCount: Int) -> some View {
        let isFilled   = index < safeCount
        let isNext     = index == safeCount

        Image(systemName: isFilled ? "drop.fill" : (isNext ? "drop.circle" : "drop"))
            .font(.system(size: 22))
            .foregroundColor(
                isFilled ? .blue :
                isNext   ? Color("AppGreen") :
                           .gray.opacity(0.35)
            )
    }

    @ViewBuilder
    private var waterHintText: some View {
        if !trackerVM.isTodaySelected {
            Text("Past days are read-only. Water can only be changed for today")
                .font(.caption).foregroundColor(.secondary)
        } else if trackerVM.isWaterUpdating {
            HStack(spacing: 6) {
                ProgressView().scaleEffect(0.7)
                Text("Saving water…").font(.caption).foregroundColor(.secondary)
            }
        } else if let err = trackerVM.waterError {
            Text(err).font(.caption).foregroundColor(.red)
        } else {
            Text("Tap an empty cup to add water, or a filled cup to remove it")
                .font(.caption).foregroundColor(.secondary)
        }
    }

    private var historyButton: some View {
        Button { showHistory = true } label: {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                Text("View Nutrition History").fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.subheadline).foregroundColor(Color("AppGreen"))
            .padding(16).background(Color("AppGreen").opacity(0.08)).cornerRadius(14)
        }
    }
    private func loadUserHeader() async {
        guard let resp = try? await BackendUserService.shared.getMe(),
              let userData = resp.data else { return }
        userPhotoURL = userData.photo?.isEmpty == false ? userData.photo : nil
        isVip        = TokenManager.shared.isVip
    }
}
