import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authVM: BackendAuthViewModel
    @StateObject private var trackerVM = TrackerViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(trackerVM)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            ScanView()
                .environmentObject(trackerVM)
                .tabItem { Label("Scan", systemImage: "barcode.viewfinder") }
                .tag(1)

            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart.fill") }
                .tag(2)

            RecentView()
                .tabItem { Label("Recent", systemImage: "clock.fill") }
                .tag(3)
        }
        .accentColor(Color("AppGreen"))
        .onAppear {
            trackerVM.loadForDate(trackerVM.selectedDate)
        }
    }
}
