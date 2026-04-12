import SwiftUI

struct ConsumptionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedDate: Date

    @State private var historyItems: [BackendConsumptionHistoryItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView().padding(.top, 40)
                } else if historyItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No history available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Start tracking food to see your history here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(historyItems) { item in
                        HistoryDayCard(item: item)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .navigationTitle("Nutrition History")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").foregroundColor(Color("AppGreen"))
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task { await loadHistory() }
    }

    private func loadHistory() async {
        isLoading = true
        defer { isLoading = false }
        // Load 30 days of history ending on selected date
        let calendar = Calendar.current
        let endDate = selectedDate
        let startDate = calendar.date(byAdding: .day, value: -29, to: endDate) ?? endDate
        let from = dateFormatter.string(from: startDate)
        let to = dateFormatter.string(from: endDate)
        do {
            let resp = try await BackendUserService.shared.getConsumptionHistory(from: from, to: to)
            if resp.success {
                historyItems = (resp.data ?? []).sorted { ($0.date ?? "") > ($1.date ?? "") }
            } else {
                errorMessage = resp.message ?? "Failed to load history"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - History Day Card

struct HistoryDayCard: View {
    let item: BackendConsumptionHistoryItem

    private let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let out = DateFormatter()
        out.dateFormat = "dd MMM yyyy"
        return out
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date header
            HStack {
                Text(formattedDate(item.date))
                    .font(.headline)
                Spacer()
                if let cal = item.calories, let goal = item.caloriesGoal, goal > 0 {
                    let pct = min(Int(Double(cal) / Double(goal) * 100), 100)
                    Text("\(pct)% of goal")
                        .font(.caption)
                        .foregroundColor(pct > 90 ? .red : Color("AppGreen"))
                        .fontWeight(.semibold)
                }
            }

            // Main macros row
            HStack(spacing: 0) {
                macroCell(
                    label: "Calories",
                    consumed: item.calories,
                    goal: item.caloriesGoal,
                    unit: "kcal",
                    color: Color(hex: "#F59E0B")
                )
                Divider()
                macroCell(
                    label: "Protein",
                    consumed: item.proteins,
                    goal: item.proteinGoal,
                    unit: "g",
                    color: Color(hex: "#3B82F6")
                )
                Divider()
                macroCell(
                    label: "Carbs",
                    consumed: item.carbs,
                    goal: item.carbsGoal,
                    unit: "g",
                    color: Color(hex: "#10B981")
                )
                Divider()
                macroCell(
                    label: "Fat",
                    consumed: item.fat,
                    goal: item.fatGoal,
                    unit: "g",
                    color: Color(hex: "#EF4444")
                )
            }
            .frame(height: 64)
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Water row
            if let water = item.water, let waterGoal = item.waterGoal, waterGoal > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Water: \(String(format: "%.2f", Double(water)/1000.0)) L / \(String(format: "%.2f", Double(waterGoal)/1000.0)) L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    @ViewBuilder
    private func macroCell(label: String, consumed: Int?, goal: Int?, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("\(consumed ?? 0)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            Text("/ \(goal ?? 0) \(unit)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formattedDate(_ dateStr: String?) -> String {
        guard let dateStr = dateStr else { return "Unknown" }
        let inFmt = DateFormatter()
        inFmt.dateFormat = "yyyy-MM-dd"
        inFmt.locale = Locale(identifier: "en_US_POSIX")
        let outFmt = DateFormatter()
        outFmt.dateFormat = "EEE, dd MMM yyyy"
        if let date = inFmt.date(from: dateStr) {
            return outFmt.string(from: date)
        }
        return dateStr
    }
}
