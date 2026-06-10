import SwiftUI

struct ExportReportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var fromDate: Date = Calendar.current.date(byAdding: .day, value: -29, to: Date()) ?? Date()
    @State private var toDate: Date = Date()
    @State private var showFromPicker = false
    @State private var showToPicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var exportFormat: ExportFormat = .csv
    @State private var showShareSheet = false
    @State private var sharedURL: URL?
    @State private var historyItems: [BackendConsumptionHistoryItem] = []

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case pdf = "PDF"
    }

    private let displayFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM dd, yyyy"; return f
    }()
    private let apiFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX"); return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Format selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export Format".localized)
                            .font(.subheadline).fontWeight(.semibold)
                        Picker("", selection: $exportFormat) {
                            ForEach(ExportFormat.allCases, id: \.self) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)

                    // Date range
                    VStack(spacing: 0) {
                        dateRow(label: "From".localized, date: fromDate, isExpanded: $showFromPicker) {
                            showToPicker = false
                        }
                        Divider().padding(.horizontal)
                        dateRow(label: "To".localized, date: toDate, isExpanded: $showToPicker) {
                            showFromPicker = false
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                    .padding(.horizontal)

                    if let err = errorMessage {
                        Text(err).font(.caption).foregroundColor(.red).padding(.horizontal)
                    }

                    Button {
                        Task { await generateReport() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white).padding(.trailing, 4)
                            }
                            Text(isLoading ? "Generating...".localized : "Generate Report".localized)
                                .font(.headline).foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity).padding(16)
                        .background(Color("AppGreen")).cornerRadius(14)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Export Report".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").foregroundColor(Color("AppGreen"))
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = sharedURL {
                    ShareSheet(url: url)
                }
            }
        }
    }

    @ViewBuilder
    private func dateRow(label: String, date: Date, isExpanded: Binding<Bool>, onTap: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                onTap()
                isExpanded.wrappedValue.toggle()
            } label: {
                HStack {
                    Text(label).font(.subheadline).foregroundColor(.primary)
                    Spacer()
                    Text(displayFmt.string(from: date))
                        .font(.subheadline).foregroundColor(Color("AppGreen")).fontWeight(.medium)
                    Image(systemName: "chevron.down")
                        .font(.caption).foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 180 : 0))
                }
                .padding(16)
            }
            if isExpanded.wrappedValue {
                DatePicker("", selection: label == "From".localized ? $fromDate : $toDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)
                    .tint(Color("AppGreen"))
            }
        }
    }

    private func generateReport() async {
        guard fromDate <= toDate else {
            errorMessage = "Start date must be before end date".localized; return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let from = apiFmt.string(from: fromDate)
        let to = apiFmt.string(from: toDate)

        do {
            if exportFormat == .pdf {
                let data = try await BackendUserService.shared.downloadConsumptionReportPdf(from: from, to: to)
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("ScanFit_Report_\(from)_\(to).pdf")
                try data.write(to: url)
                sharedURL = url
                showShareSheet = true
            } else {
                let resp = try await BackendUserService.shared.getConsumptionHistory(from: from, to: to)
                guard resp.success, let items = resp.data else {
                    errorMessage = resp.message ?? "Failed to load data".localized; return
                }
                let csvUrl = generateCSV(items: items, from: from, to: to)
                sharedURL = csvUrl
                showShareSheet = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func generateCSV(items: [BackendConsumptionHistoryItem], from: String, to: String) -> URL {
        var csv = "ScanFit Health Report\n"
        csv += "Period,\(from),\(to)\n"
        csv += "Generated,\(apiFmt.string(from: Date()))\n\n"
        csv += "Date,Calories,Cal Goal,Protein(g),Protein Goal,Carbs(g),Carbs Goal,Fat(g),Fat Goal,Water(ml),Water Goal,Sodium(mg),Fiber(g),Sugar(g),Cholesterol(mg),Vit A,Vit B6,Vit B9,Vit B12,Vit C,Vit D,Vit E\n"

        func fmt(_ v: Double?) -> String { String(format: "%.2f", v ?? 0) }

        for item in items.sorted(by: { ($0.date ?? "") > ($1.date ?? "") }) {
            csv += "\(item.date ?? ""),\(item.calories ?? 0),\(item.caloriesGoal ?? 0),"
            csv += "\(item.proteins ?? 0),\(item.proteinGoal ?? 0),"
            csv += "\(item.carbs ?? 0),\(item.carbsGoal ?? 0),"
            csv += "\(item.fat ?? 0),\(item.fatGoal ?? 0),"
            csv += "\(item.water ?? 0),\(item.waterGoal ?? 0),"
            csv += "\(item.sodium ?? 0),\(item.fiber ?? 0),\(item.sugar ?? 0),\(item.cholesterol ?? 0),"
            csv += "\(fmt(item.vitaminA)),\(fmt(item.vitaminB6)),\(fmt(item.vitaminB9)),\(fmt(item.vitaminB12)),"
            csv += "\(fmt(item.vitaminC)),\(fmt(item.vitaminD)),\(fmt(item.vitaminE))\n"
        }

        if !items.isEmpty {
            csv += "\n--- AVERAGES ---\n"
            csv += "Avg Calories,\(items.map { $0.calories ?? 0 }.reduce(0, +) / items.count)\n"
            csv += "Avg Protein(g),\(items.map { $0.proteins ?? 0 }.reduce(0, +) / items.count)\n"
            csv += "Avg Carbs(g),\(items.map { $0.carbs ?? 0 }.reduce(0, +) / items.count)\n"
            csv += "Avg Fat(g),\(items.map { $0.fat ?? 0 }.reduce(0, +) / items.count)\n"
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ScanFit_Report_\(from)_\(to).csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
