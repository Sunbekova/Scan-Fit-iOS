import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        Group {
            switch authViewModel.state {
            case .loading:
                SplashView()
            case .unauthenticated:
                NavigationStack {
                    LoginView()
                }
            case .profileIncomplete:
                NavigationStack {
                    ProfileSetupView()
                }
            case .authenticated:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.state)
    }
}
