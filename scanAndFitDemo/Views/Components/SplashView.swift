import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color("AppGreen")
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "barcode.viewfinder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                Text("ScanFit")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                Text("Your health companion")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}
