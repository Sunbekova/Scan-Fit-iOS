import SwiftUI

struct ProSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authVM: BackendAuthViewModel
    @State private var isLoading = false
    @State private var showBuySheet = false
    @State private var errorMessage: String?
    @State private var scanLimit: BackendProductScanLimitData?
    @State private var isVip = TokenManager.shared.isVip

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                proHeaderBanner
                VStack(alignment: .leading, spacing: 24) {
                    currentPlanCard
                    scanLimitCard
                    featuresSection
                    if !isVip { upgradeButton } else { vipActiveCard }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").foregroundColor(Color("AppGreen"))
                }
            }
        }
        .navigationTitle(isVip ? "ScanFit Pro" : "Upgrade to Pro")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
        .sheet(isPresented: $showBuySheet) { BuyVipSheet(isPresented: $showBuySheet, onPurchased: onPurchased) }
        .task {
            await loadScanLimit()
            isVip = TokenManager.shared.isVip
        }
    }

    private var proHeaderBanner: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#0F172A"), Color(hex: "#1E293B")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 52)).foregroundColor(Color(hex: "#FBBF24"))
                Text("ScanFit Pro")
                    .font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                Text("Unlimited scans & advanced health insights")
                    .font(.subheadline).foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            .padding(.vertical, 48)
        }
    }

    private var currentPlanCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Plan").font(.caption).foregroundColor(.secondary)
                Text(isVip ? "ScanFit Pro" : "Basic")
                    .font(.title3).fontWeight(.bold)
                    .foregroundColor(isVip ? Color(hex: "#0F172A") : .primary)
            }
            Spacer()
            if isVip {
                Label("Active", systemImage: "checkmark.seal.fill")
                    .font(.caption).fontWeight(.semibold).foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color("AppGreen")).cornerRadius(20)
            } else {
                Text("Free")
                    .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color(.systemGray5)).cornerRadius(20)
            }
        }
        .padding(20).background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var scanLimitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Scan Usage").font(.headline)
            if let limit = scanLimit {
                let unlimited = limit.isUnlimited ?? false
                let remaining = limit.remaining ?? 0
                let used = limit.used ?? 0
                let total = limit.limit ?? 5

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if unlimited {
                            Text("Unlimited scans").font(.title3).fontWeight(.bold)
                                .foregroundColor(Color("AppGreen"))
                        } else {
                            Text("\(remaining) remaining").font(.title3).fontWeight(.bold)
                                .foregroundColor(remaining > 0 ? .primary : .red)
                            Text("Used \(used) of \(total) today")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: unlimited ? "infinity" : "barcode.viewfinder")
                        .font(.system(size: 28))
                        .foregroundColor(unlimited ? Color("AppGreen") : (remaining > 0 ? .primary : .red))
                }
                if !unlimited {
                    ProgressView(value: Double(used), total: Double(total))
                        .accentColor(remaining > 0 ? Color("AppGreen") : .red)
                    if let resetsAt = limit.resetsAtUtc {
                        Text("Resets at: \(formattedResetTime(resetsAt))").font(.caption2).foregroundColor(.secondary)
                    }
                }
            } else if isLoading {
                ProgressView()
            } else {
                Text("Could not load scan limit info").font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(20).background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's included").font(.headline)
            VStack(spacing: 0) {
                featureRow(title: "     Features", basic: "BASIC", pro: "PRO", icon: "crown.fill", highlight: true)
                Divider().padding(.leading, 48)
                featureRow(title: "Daily AI Scans", basic: "15 per day", pro: "Unlimited", icon: "barcode.viewfinder", highlight: false)
                Divider().padding(.leading, 48)
                featureRow(title: "AI Health Analysis", basic: "Basic", pro: "Full + Sources", icon: "brain.head.profile", highlight: false)
                Divider().padding(.leading, 48)
                featureRow(title: "Blood Pressure", basic: "—", pro: "✓", icon: "heart.text.square", highlight: false)
                Divider().padding(.leading, 48)
                featureRow(title: "Cholesterol Tracking", basic: "—", pro: "✓", icon: "drop.fill", highlight: false)
                Divider().padding(.leading, 48)
                featureRow(title: "Disease Management", basic: "Up to 3", pro: "Unlimited", icon: "cross.case", highlight: false)
                Divider().padding(.leading, 48)
                featureRow(title: "Dietary Preferences", basic: "—", pro: "Full Access", icon: "leaf", highlight: false)
                Divider().padding(.leading, 48)
                featureRow(title: "Vitamin Tracking", basic: "—", pro: "All Vitamins", icon: "pills.fill", highlight: false)
            }
            .background(Color(.systemBackground)).cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
    }

    @ViewBuilder
    private func featureRow(title: String, basic: String, pro: String, icon: String, highlight: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(Color("AppGreen")).frame(width: 28)
            Text(title).font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
            Text(basic).font(.caption).foregroundColor(.secondary).frame(width: 70, alignment: .center)
            Text(pro).font(.caption).fontWeight(.semibold).foregroundColor(Color("AppGreen")).frame(width: 70, alignment: .center)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(highlight ? Color("AppGreen").opacity(0.05) : Color.clear)
    }

    private var upgradeButton: some View {
        VStack(spacing: 12) {
            Button { showBuySheet = true } label: {
                HStack {
                    Image(systemName: "crown.fill").foregroundColor(Color(hex: "#FBBF24"))
                    Text("Upgrade to ScanFit Pro").fontWeight(.bold)
                }
                .font(.headline).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(18)
                .background(LinearGradient(colors: [Color(hex: "#0F172A"), Color(hex: "#1E3A5F")],
                                           startPoint: .leading, endPoint: .trailing))
                .cornerRadius(16)
            }
            Text("Contact support via Telegram or WhatsApp to complete upgrade")
                .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
    }

    private var vipActiveCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "crown.fill").font(.system(size: 32)).foregroundColor(Color(hex: "#FBBF24"))
            VStack(alignment: .leading, spacing: 4) {
                Text("You're a Pro member!").font(.headline).foregroundColor(Color(hex: "#FBBF24"))
                Text("Enjoy unlimited scans and all premium features.")
                    .font(.caption).foregroundColor(Color("AppGreen"))
            }
            Spacer()
        }
        .padding(20).background(Color(hex: "#0F172A")).cornerRadius(16)
    }

    private func loadScanLimit() async {
        isLoading = true
        if let resp = try? await BackendUserService.shared.getProductScanLimit() { scanLimit = resp.data }
        isLoading = false
    }

    private func onPurchased() {
        isVip = true
        Task {
            await authVM.refreshRole()
            await loadScanLimit()
        }
    }

    private func formattedResetTime(_ utcString: String) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fmt.date(from: utcString) {
            let out = DateFormatter(); out.dateStyle = .none; out.timeStyle = .short
            return out.string(from: date)
        }
        return utcString
    }
}

//buy VIP  (Telegram + WhatsApp contact + demo backend call)
struct BuyVipSheet: View {
    @Binding var isPresented: Bool
    var onPurchased: () -> Void

    @State private var isLoading   = false
    @State private var showSuccess = false
    @State private var errorMsg: String?
//menedjers
    private let telegramUsername  = "@aqzsha"
    private let whatsappNumber    = "+77079897710"

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "crown.fill")
                    .font(.system(size: 64)).foregroundColor(Color(hex: "#FBBF24"))

                Text("Upgrade to ScanFit Pro").font(.title2).fontWeight(.bold)

                Text("Choose how to contact us to complete your upgrade. Once confirmed, your account will be upgraded to Pro.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 24)
                Button {
                    openTelegram()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "paperplane.fill")
                        Text("Contact via Telegram")
                    }
                    .font(.headline).fontWeight(.semibold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(16)
                    .background(Color(hex: "#2CA5E0")).cornerRadius(14)
                    .padding(.horizontal, 24)
                }
                Button {
                    openWhatsApp()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "phone.fill")
                        Text("Contact via WhatsApp")
                    }
                    .font(.headline).fontWeight(.semibold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(16)
                    .background(Color(hex: "#25D366")).cornerRadius(14)
                    .padding(.horizontal, 24)
                }

                Divider().padding(.horizontal, 24)
                if isLoading {
                    ProgressView()
                } else if showSuccess {
                    Label("Upgrade requested! We'll confirm soon.", systemImage: "checkmark.circle.fill")
                        .font(.subheadline).foregroundColor(Color("AppGreen"))
                        .padding(.horizontal, 24)
                } else {
                    Button {
                        Task { await requestUpgrade() }
                    } label: {
                        Text("Request upgrade (demo)")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                }

                if let err = errorMsg {
                    Text(err).font(.caption).foregroundColor(.red).padding(.horizontal, 24)
                }

                Spacer()
            }
            .navigationTitle("Pro Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { isPresented = false }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func openTelegram() {
        let urlStr = "https://t.me/\(telegramUsername)"
        if let url = URL(string: urlStr) { UIApplication.shared.open(url) }
    }

    private func openWhatsApp() {
        let number = whatsappNumber.replacingOccurrences(of: "+", with: "")
        let msg = "Hello! I'd like to upgrade my ScanFit account to Pro.".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = "https://wa.me/\(number)?text=\(msg)"
        if let url = URL(string: urlStr) { UIApplication.shared.open(url) }
    }
    private func requestUpgrade() async {
        isLoading = true; errorMsg = nil
        defer { isLoading = false }
        guard let url = URL(string: AppConfig.backendBaseURL + "/api/v1/user/buy-vip"),
              let bearer = TokenManager.shared.bearerToken else {
            errorMsg = "Not logged in"; return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(bearer, forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [:])
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                showSuccess = true
                // Attempt to parse role from response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let roleCode = (json["data"] as? [String: Any])?["role"] as? String {
                    TokenManager.shared.userRole = roleCode
                }
                onPurchased()
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["message"] as? String {
                    errorMsg = msg
                } else {
                    showSuccess = true
                }
            }
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}
