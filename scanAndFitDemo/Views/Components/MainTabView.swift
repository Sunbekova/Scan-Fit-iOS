import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authVM: BackendAuthViewModel
    @StateObject private var trackerVM = TrackerViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(trackerVM)
                .environmentObject(authVM)
                .tabItem { Label("Home".localized, systemImage: "house.fill") }
                .tag(0)

            ScanView()
                .environmentObject(trackerVM)
                .tabItem { Label("Scan".localized, systemImage: "barcode.viewfinder") }
                .tag(1)

            FavoritesView()
                .environmentObject(trackerVM)
                .tabItem { Label("Favorites".localized, systemImage: "heart.fill") }
                .tag(2)

            RecentView()
                .environmentObject(trackerVM)
                .tabItem { Label("Recent".localized, systemImage: "clock.fill") }
                .tag(3)
        }
        .accentColor(Color("AppGreen"))
        .task {
            trackerVM.loadForDate(trackerVM.selectedDate)
            await trackerVM.loadFirstAvailableDay()
            // Request notification permission
            NotificationManager.shared.requestPermission()
        }
    }
}
