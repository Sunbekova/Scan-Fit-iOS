import SwiftUI
import Charts

struct ConsumptionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedDate: Date

    @State private var historyItems: [BackendConsumptionHistoryItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showExportSheet = false
    @State private var selectedChartMetric: ChartMetric = .calories

    enum ChartMetric: String, CaseIterable {
        case calories = "Calories"
        case protein = "Protein"
        case carbs = "Carbs"
        case fat = "Fat"
        case water = "Water"
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    var avgCalories: Int {
        guard !historyItems.isEmpty else { return 0 }
        return historyItems.map { $0.calories ?? 0 }.reduce(0, +) / historyItems.count
    }

    var avgWaterLiters: Double {
        guard !historyItems.isEmpty else { return 0 }
        let total = historyItems.map { Double($0.water ?? 0) }.reduce(0, +)
        return (total / Double(historyItems.count)) / 1000.0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView().padding(.top, 40)
                } else if historyItems.isEmpty {
                    emptyState
                } else {
                    // Summary cards
                    HStack(spacing: 12) {
                        summaryCard(title: "Avg Calories".localized, value: "\(avgCalories) kcal", color: Color(hex: "#F59E0B"))
                        summaryCard(title: "Avg Water".localized, value: String(format: "%.2f L", avgWaterLiters), color: Color(hex: "#3B82F6"))
                    }

                    // Chart
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Weekly Trend".localized)
                            .font(.subheadline).fontWeight(.semibold)

                        // Metric picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ChartMetric.allCases, id: \.self) { metric in
                                    Button(metric.rawValue.localized) { selectedChartMetric = metric }
                                        .font(.caption).fontWeight(.medium)
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(selectedChartMetric == metric ? Color("AppGreen") : Color(.systemGray5))
                                        .foregroundColor(selectedChartMetric == metric ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }

                        // iOS 16+ Charts
                        if #available(iOS 16.0, *) {
                            Chart {
                                ForEach(chartData, id: \.date) { point in
                                    BarMark(
                                        x: .value("Date", point.dateLabel),
                                        y: .value("Value", point.value)
                                    )
                                    .foregroundStyle(Color("AppGreen").gradient)
                                    .cornerRadius(6)
                                }
                            }
                            .frame(height: 160)
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                        } else {
                            legacyBarChart
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                    // Export button
                    Button {
                        showExportSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.doc")
                            Text("Export Report".localized)
                        }
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(Color("AppGreen"))
                        .frame(maxWidth: .infinity).padding(14)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("AppGreen"), lineWidth: 1.5))
                    }

                    // Day cards
                    ForEach(historyItems) { item in
                        HistoryDayCard(item: item)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .navigationTitle("Nutrition History".localized)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").foregroundColor(Color("AppGreen"))
                }
            }
        }
        .alert("Error".localized, isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK".localized, role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showExportSheet) {
            ExportReportView()
        }
        .task { await loadHistory() }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No history available".localized)
                .font(.headline).foregroundColor(.secondary)
            Text("Start tracking food to see your history here.".localized)
                .font(.caption).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    private func summaryCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.headline).fontWeight(.bold).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // Chart data from selected metric
    private struct ChartPoint { let date: String; let dateLabel: String; let value: Double }
    private var chartData: [ChartPoint] {
        historyItems.prefix(7).compactMap { item in
            guard let date = item.date else { return nil }
            let label = String(date.suffix(2))
            let value: Double
            switch selectedChartMetric {
            case .calories: value = Double(item.calories ?? 0)
            case .protein:  value = Double(item.proteins ?? 0)
            case .carbs:    value = Double(item.carbs ?? 0)
            case .fat:      value = Double(item.fat ?? 0)
            case .water:    value = Double(item.water ?? 0) / 1000.0
            }
            return ChartPoint(date: date, dateLabel: label, value: value)
        }.reversed()
    }

    // Fallback bar chart for iOS < 16
    private var legacyBarChart: some View {
        let data = chartData
        let maxVal = data.map(\.value).max() ?? 1
        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(data, id: \.date) { point in
                VStack(spacing: 2) {
                    Text(String(format: point.value >= 100 ? "%.0f" : "%.1f", point.value))
                        .font(.system(size: 8)).foregroundColor(.secondary)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("AppGreen"))
                        .frame(height: max(8, CGFloat(point.value / maxVal * 100)))
                    Text(point.dateLabel).font(.system(size: 9)).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 130)
    }

    private func loadHistory() async {
        isLoading = true
        defer { isLoading = false }
        let calendar = Calendar.current
        let endDate = selectedDate
        let startDate = calendar.date(byAdding: .day, value: -29, to: endDate) ?? endDate
        let from = dateFormatter.string(from: startDate)
        let to = dateFormatter.string(from: endDate)
        do {
            let resp = try await BackendUserService.shared.getConsumptionHistory(from: from, to: to)
            if resp.success, let items = resp.data {
                historyItems = items.sorted { $0.date ?? "" > $1.date ?? "" }
            } else {
                errorMessage = "Failed to load history".localized
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - History Day Card

struct HistoryDayCard: View {
    let item: BackendConsumptionHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            HStack(spacing: 0) {
                macroCell(label: "Calories".localized, consumed: item.calories, goal: item.caloriesGoal, unit: "kcal", color: Color(hex: "#F59E0B"))
                Divider()
                macroCell(label: "Protein".localized, consumed: item.proteins, goal: item.proteinGoal, unit: "g", color: Color(hex: "#3B82F6"))
                Divider()
                macroCell(label: "Carbs".localized, consumed: item.carbs, goal: item.carbsGoal, unit: "g", color: Color(hex: "#10B981"))
                Divider()
                macroCell(label: "Fat".localized, consumed: item.fat, goal: item.fatGoal, unit: "g", color: Color(hex: "#EF4444"))
            }
            .frame(height: 64)
            .background(Color(.systemGray6))
            .cornerRadius(12)

            if let water = item.water, let waterGoal = item.waterGoal, waterGoal > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "drop.fill").foregroundColor(.blue).font(.caption)
                    Text("Water: \(String(format: "%.2f", Double(water)/1000.0)) L / \(String(format: "%.2f", Double(waterGoal)/1000.0)) L")
                        .font(.caption).foregroundColor(.secondary)
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
            Text(label).font(.caption2).foregroundColor(.secondary)
            Text("\(consumed ?? 0)").font(.system(size: 16, weight: .bold)).foregroundColor(color)
            Text("/ \(goal ?? 0) \(unit)").font(.caption2).foregroundColor(.secondary)
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
