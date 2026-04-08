import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Image(AppImages.splashBackground)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(AppImages.mascot)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                Text("ScanFit")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
            }
        }
    }
}
