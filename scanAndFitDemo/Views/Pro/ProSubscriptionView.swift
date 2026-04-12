import SwiftUI

// MARK: - Pro Subscription / VIP Upgrade View
// Matches Android proSubscriptionFragment design

struct ProSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showConfirmation = false
    @State private var errorMessage: String?
    @State private var scanLimit: BackendProductScanLimitData?

    private let isVip = TokenManager.shared.isVip

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header banner
                proHeaderBanner

                VStack(alignment: .leading, spacing: 24) {
                    // Current plan card
                    currentPlanCard

                    // Scan limit card
                    scanLimitCard

                    // Features comparison
                    featuresSection

                    // Upgrade button (only for non-VIP)
                    if !isVip {
                        upgradeButton
                    } else {
                        vipActiveCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color("AppGreen"))
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
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showConfirmation) {
            PurchaseConfirmationSheet(isPresented: $showConfirmation)
        }
        .task { await loadScanLimit() }
    }

    // MARK: - Header Banner

    private var proHeaderBanner: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0F172A"), Color(hex: "#1E293B")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 52))
                    .foregroundColor(Color(hex: "#FBBF24"))
                Text("ScanFit Pro")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("Unlock unlimited scans & advanced health insights")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.vertical, 48)
        }
    }

    // MARK: - Current Plan Card

    private var currentPlanCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Plan")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(isVip ? "ScanFit Pro" : "Basic")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isVip ? Color(hex: "#0F172A") : .primary)
            }
            Spacer()
            if isVip {
                Label("Active", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("AppGreen"))
                    .cornerRadius(20)
            } else {
                Text("Free")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(20)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Scan Limit Card

    private var scanLimitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Scan Usage")
                .font(.headline)

            if let limit = scanLimit {
                let isUnlimited = limit.isUnlimited ?? false
                let remaining = limit.remaining ?? 0
                let used = limit.used ?? 0
                let total = limit.limit ?? 5

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if isUnlimited {
                            Text("Unlimited scans")
                                .font(.title3).fontWeight(.bold)
                                .foregroundColor(Color("AppGreen"))
                        } else {
                            Text("\(remaining) remaining")
                                .font(.title3).fontWeight(.bold)
                                .foregroundColor(remaining > 0 ? .primary : .red)
                            Text("Used \(used) of \(total) today")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: isUnlimited ? "infinity" : "barcode.viewfinder")
                        .font(.system(size: 28))
                        .foregroundColor(isUnlimited ? Color("AppGreen") : (remaining > 0 ? .primary : .red))
                }

                if !isUnlimited {
                    ProgressView(value: Double(used), total: Double(total))
                        .accentColor(remaining > 0 ? Color("AppGreen") : .red)

                    if let resetsAt = limit.resetsAtUtc {
                        Text("Resets at: \(formattedResetTime(resetsAt))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } else if isLoading {
                ProgressView()
            } else {
                Text("Could not load scan limit info")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's included")
                .font(.headline)

            VStack(spacing: 0) {
                featureRow(
                    title: "Daily AI Scans",
                    basic: "5 per day",
                    pro: "Unlimited",
                    icon: "barcode.viewfinder",
                    isHighlighted: true
                )
                Divider().padding(.leading, 48)
                featureRow(
                    title: "AI Health Analysis",
                    basic: "Basic",
                    pro: "Full + Sources",
                    icon: "brain.head.profile",
                    isHighlighted: false
                )
                Divider().padding(.leading, 48)
                featureRow(
                    title: "Blood Pressure Tracking",
                    basic: "—",
                    pro: "✓",
                    icon: "heart.text.square",
                    isHighlighted: false
                )
                Divider().padding(.leading, 48)
                featureRow(
                    title: "Cholesterol Tracking",
                    basic: "—",
                    pro: "✓",
                    icon: "drop.fill",
                    isHighlighted: false
                )
                Divider().padding(.leading, 48)
                featureRow(
                    title: "Disease Management",
                    basic: "Up to 3",
                    pro: "Unlimited",
                    icon: "cross.case",
                    isHighlighted: false
                )
                Divider().padding(.leading, 48)
                featureRow(
                    title: "Dietary Preferences",
                    basic: "—",
                    pro: "Full Access",
                    icon: "leaf",
                    isHighlighted: false
                )
                Divider().padding(.leading, 48)
                featureRow(
                    title: "Vitamin Tracking",
                    basic: "—",
                    pro: "All Vitamins",
                    icon: "pills.fill",
                    isHighlighted: false
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
    }

    @ViewBuilder
    private func featureRow(title: String, basic: String, pro: String, icon: String, isHighlighted: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color("AppGreen"))
                .frame(width: 28)

            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(basic)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .center)

            Text(pro)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("AppGreen"))
                .frame(width: 70, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(isHighlighted ? Color("AppGreen").opacity(0.05) : Color.clear)
    }

    // MARK: - Upgrade Button

    private var upgradeButton: some View {
        VStack(spacing: 12) {
            Button {
                showConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(Color(hex: "#FBBF24"))
                    Text("Upgrade to ScanFit Pro")
                        .fontWeight(.bold)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#0F172A"), Color(hex: "#1E3A5F")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }

            Text("Contact your administrator to upgrade your account")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - VIP Active Card

    private var vipActiveCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "#FBBF24"))
            VStack(alignment: .leading, spacing: 4) {
                Text("You're a Pro member!")
                    .font(.headline)
                Text("Enjoy unlimited scans and all premium features.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .background(Color(hex: "#0F172A"))
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private func loadScanLimit() async {
        isLoading = true
        do {
            let resp = try await BackendUserService.shared.getProductScanLimit()
            scanLimit = resp.data
        } catch {
            // silently ignore
        }
        isLoading = false
    }

    private func formattedResetTime(_ utcString: String) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fmt.date(from: utcString) {
            let out = DateFormatter()
            out.dateStyle = .none
            out.timeStyle = .short
            return out.string(from: date)
        }
        return utcString
    }
}

// MARK: - Purchase Confirmation Sheet

struct PurchaseConfirmationSheet: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "crown.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color(hex: "#FBBF24"))

                Text("Upgrade to ScanFit Pro")
                    .font(.title2).fontWeight(.bold)

                Text("To upgrade your account, please contact support or your administrator. Pro access grants you unlimited daily scans, full AI analysis, and all premium health tracking features.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button {
                    isPresented = false
                } label: {
                    Text("Close")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AppGreen"))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                }
                Spacer()
            }
            .navigationTitle("Pro Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}
