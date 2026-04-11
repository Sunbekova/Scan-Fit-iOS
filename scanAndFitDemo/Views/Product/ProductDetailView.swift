import SwiftUI
import SwiftData

struct ProductDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var trackerVM: TrackerViewModel

    let foodItem: FoodItem?
    let analysisResponse: AnalysisResponse?

    @State private var isFavorite = false
    @State private var aiResponse: AnalysisResponse?
    @State private var isAnalyzing = false
    @State private var analysisFailed = false
    @State private var servingMultiplier: Double = 1.0
    @State private var currentScanId: Int? = nil

    private var hasProductDetails: Bool { foodItem != nil }

    init(foodItem: FoodItem? = nil, analysisResponse: AnalysisResponse? = nil) {
        self.foodItem = foodItem
        self.analysisResponse = analysisResponse
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection.padding(.bottom, 20)
                VStack(alignment: .leading, spacing: 20) {
                    gradeRow
                    if hasProductDetails { servingSelector }
                    macroSection
                    aiVerdictSection
                    nutrientsSection
                    addToTrackerButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").foregroundColor(Color("AppGreen"))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if hasProductDetails {
                    Button { toggleFavorite() } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .gray)
                    }
                }
            }
        }
        .onAppear {
            if let item = foodItem {
                checkFavoriteStatus(item)
                saveToRecent(item)
                if analysisResponse == nil {
                    Task { await loadSavedProductScan(for: item) }
                }
            }
            if let resp = analysisResponse { aiResponse = resp }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let urlStr = foodItem?.imageURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: placeholderHeader
                    }
                }
                .frame(height: 240).clipped()
            } else {
                placeholderHeader.frame(height: 240)
            }
            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) {
                Text(foodItem?.subtitle ?? (aiResponse != nil ? "SCANNER" : "PRODUCT"))
                    .font(.caption).fontWeight(.semibold).foregroundColor(.white.opacity(0.8)).textCase(.uppercase)
                Text(foodItem?.title ?? aiResponse?.productName ?? "AI Analysis")
                    .font(.title2).fontWeight(.bold).foregroundColor(.white)
            }
            .padding(.horizontal, 20).padding(.bottom, 20)
        }
    }

    private var placeholderHeader: some View {
        Rectangle().fill(Color("AppGreen").opacity(0.15))
            .overlay(Image(systemName: "fork.knife.circle.fill").font(.system(size: 64))
                .foregroundColor(Color("AppGreen").opacity(0.4)))
    }

    // MARK: - Grade Row

    private var gradeRow: some View {
        HStack(spacing: 16) {
            let grade = currentGrade
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(gradeColor(grade)).frame(width: 52, height: 52)
                Text(grade).font(.system(size: 22, weight: .bold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Nutri-Score").font(.caption).foregroundColor(.secondary)
                Text(gradeLabel(grade)).font(.subheadline).fontWeight(.semibold).foregroundColor(gradeColor(grade))
            }
            Spacer()
            if let score = aiResponse?.healthScore {
                VStack(spacing: 2) {
                    Text("\(score)").font(.system(size: 22, weight: .bold))
                        .foregroundColor(gradeColor(currentGrade))
                    Text("Health Score").font(.caption2).foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - tamaq porcia

    private let portionValues: [Double] = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0]

    private var servingSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Serving size").font(.subheadline).fontWeight(.semibold)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(portionValues, id: \.self) { val in
                        let isSelected = abs(val - servingMultiplier) < 0.001
                        Button {
                            servingMultiplier = val
                        } label: {
                            Text(formatAmount(val))
                                .font(.caption).fontWeight(isSelected ? .bold : .regular)
                                .frame(width: 44, height: 44)
                                .background(isSelected ? Color(hex: "#EEEBDD") : Color(.systemBackground))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    // MARK: - Macros

    private var macroSection: some View {
        HStack(spacing: 16) {
            MacroProgressItem(title: "Protein", value: currentProteins, maxValue: 50, color: .green)
            MacroProgressItem(title: "Carbs", value: currentCarbs, maxValue: 75, color: .orange)
            MacroProgressItem(title: "Fat", value: currentFat, maxValue: 30, color: .pink)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    // MARK: - ии

    private var aiVerdictSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Analysis").font(.headline)
                    if let resp = aiResponse {
                        let riskLabel = resp.riskLevel?.capitalized ?? (resp.healthScore ?? 0 < 40 ? "Dangerous" : "Safe")
                        Text(riskLabel)
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(gradeColor(currentGrade))
                    } else {
                        Text("Not analyzed yet").font(.subheadline).foregroundColor(.secondary)
                    }
                }
                Spacer()
                if isAnalyzing {
                    ProgressView()
                } else {
                    Button(aiResponse != nil ? "Analyze again" : "Analyze with AI") {
                        if let item = foodItem { Task { await startAIAnalysis(for: item) } }
                    }
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color("AppGreen"))
                    .cornerRadius(20)
                    .disabled(foodItem == nil)
                }
            }

            if let resp = aiResponse, let verdict = resp.verdict {
                Text(verdict).font(.subheadline).foregroundColor(.secondary)
            } else if !isAnalyzing {
                Text("Tap Analyze with AI to check this product against your profile.")
                    .font(.caption).foregroundColor(.secondary)
            }

            // Risks
            if let risks = aiResponse?.risks, !risks.isEmpty {
                aiSectionCard(title: "Risks", subtitle: "What may be a problem", bgColor: Color(hex: "#FFF3E8")) {
                    ForEach(risks) { risk in
                        aiIssueRow(title: risk.ingredient ?? "Issue",
                                   body: risk.reason ?? "Needs attention.",
                                   severity: risk.severity)
                    }
                }
            }

            // diet conflicts
            if let conflicts = aiResponse?.dietConflicts, !conflicts.isEmpty {
                aiSectionCard(title: "Diet conflicts", subtitle: "Compared with active diets", bgColor: Color(hex: "#F0F7FF")) {
                    ForEach(conflicts) { conflict in
                        aiIssueRow(title: conflict.dietCode ?? "Diet conflict",
                                   body: conflict.reason ?? "May not match one of the selected diets.",
                                   severity: conflict.severity)
                    }
                }
            }

            // sources
            if let sources = aiResponse?.sources, !sources.isEmpty {
                aiSectionCard(title: "Sources", subtitle: "Evidence used by AI", bgColor: Color(.systemGray6)) {
                    ForEach(sources.prefix(4)) { source in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(source.title ?? "Source").font(.caption).fontWeight(.bold)
                            Text(source.url ?? source.sourceType ?? "No link").font(.caption2).foregroundColor(.secondary)
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    @ViewBuilder
    private func aiSectionCard<Content: View>(title: String, subtitle: String, bgColor: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline).fontWeight(.bold)
            Text(subtitle).font(.caption).foregroundColor(.secondary)
            content()
        }
        .padding(14)
        .background(bgColor)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))
    }

    @ViewBuilder
    private func aiIssueRow(title: String, body: String, severity: String?) -> some View {
        let sColor = severityColor(severity)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption).fontWeight(.bold).foregroundColor(.primary)
                Spacer()
                Text((severity ?? "note").capitalized)
                    .font(.caption2).fontWeight(.bold).foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(sColor).cornerRadius(6)
            }
            Text(body).font(.caption).foregroundColor(.secondary)
            Divider()
        }
        .padding(.vertical, 4)
    }

    private func severityColor(_ s: String?) -> Color {
        switch s?.lowercased() {
        case "high": return Color(hex: "#DC2626")
        case "medium": return Color(hex: "#D97706")
        case "low": return Color(hex: "#2563EB")
        default: return .gray
        }
    }

    // MARK: - macros

    private var nutrientsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Nutritional Info").font(.headline).padding(.bottom, 8)

            if let item = foodItem {
                let nutrientMap: [(String, String)] = [
                    ("Total Fat", scaledVal(item.fat)),
                    ("Protein", scaledVal(item.proteins)),
                    ("Total Carbohydrate", scaledVal(item.carbs)),
                    ("Sugar", scaledVal(item.sugars ?? "0g")),
                    ("Fiber", scaledVal(item.fiber ?? "0g")),
                    ("Sodium", scaledVal(item.sodium ?? "0mg")),
                    ("Cholesterol", scaledVal(item.cholesterol ?? "0mg")),
                    ("Vitamin A", scaledVal(item.vitaminA ?? "0")),
                    ("Vitamin B12", scaledVal(item.vitaminB12 ?? "0")),
                    ("Vitamin C", scaledVal(item.vitaminC ?? "0")),
                    ("Vitamin D", scaledVal(item.vitaminD ?? "0")),
                    ("Vitamin E", scaledVal(item.vitaminE ?? "0")),
                    ("Vitamin B6", scaledVal(item.vitaminB6 ?? "0")),
                    ("Vitamin B9 (Folic acid)", scaledVal(item.vitaminB9 ?? "0")),
                ]
                ForEach(nutrientMap, id: \.0) { name, val in
                    NutrientRow(name: name, value: val)
                    Divider()
                }
            } else if let risks = aiResponse?.risks, !risks.isEmpty {
                ForEach(risks) { risk in
                    NutrientRow(name: "Risk", value: risk.ingredient ?? "Issue")
                    Divider()
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    // MARK: -Trackerge qosu

    @ViewBuilder
    private var addToTrackerButton: some View {
        if let item = foodItem {
            Button {
                Task { await addFoodToTracker(item) }
                dismiss()
            } label: {
                Text("Add to Today's Tracker")
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(16)
                    .background(Color("AppGreen"))
                    .cornerRadius(14)
            }
        } else if aiResponse != nil {
            Button {
                Task { await addAIFoodToTracker() }
                dismiss()
            } label: {
                Text("Add to Today's Tracker")
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(16)
                    .background(Color("AppGreen"))
                    .cornerRadius(14)
            }
        }
    }

    // MARK: - +backend

    private func addFoodToTracker(_ item: FoodItem) async {
        let day = trackerVM.selectedDayString
        let eatReq = BackendCreateUserDailyEatRequest(
            calorie: scaledInt(item.calories ?? "0"),
            carbohydrate: scaledInt(item.carbs),
            cholesterol: scaledInt(item.cholesterol ?? "0"),
            fats: scaledInt(item.fat),
            fiber: scaledInt(item.fiber ?? "0"),
            portion: servingMultiplier,
            productName: item.title,
            protein: scaledInt(item.proteins),
            sodium: scaledInt(item.sodium ?? "0"),
            sugar: scaledInt(item.sugars ?? "0"),
            vitaminA: scaledDouble(item.vitaminA),
            vitaminB12: scaledDouble(item.vitaminB12),
            vitaminB6: scaledDouble(item.vitaminB6),
            vitaminB9: scaledDouble(item.vitaminB9),
            vitaminC: scaledDouble(item.vitaminC),
            vitaminD: scaledDouble(item.vitaminD),
            vitaminE: scaledDouble(item.vitaminE)
        )
        let calReq = BackendUpdateUserCaloriesRequest(
            calories: scaledInt(item.calories ?? "0"),
            carbs: scaledInt(item.carbs), fat: scaledInt(item.fat),
            proteins: scaledInt(item.proteins), fiber: scaledInt(item.fiber ?? "0"),
            sodium: scaledInt(item.sodium ?? "0"), sugar: scaledInt(item.sugars ?? "0"),
            cholesterol: scaledInt(item.cholesterol ?? "0"),
            vitaminA: scaledDouble(item.vitaminA), vitaminB12: scaledDouble(item.vitaminB12),
            vitaminB6: scaledDouble(item.vitaminB6), vitaminB9: scaledDouble(item.vitaminB9),
            vitaminC: scaledDouble(item.vitaminC), vitaminD: scaledDouble(item.vitaminD),
            vitaminE: scaledDouble(item.vitaminE)
        )
        do {
            _ = try await BackendUserService.shared.createUserDailyEat(eatReq)
            let resp = try await BackendUserService.shared.updateUserCalories(day: day, req: calReq)
            if resp.success, let data = resp.data { trackerVM.applyCaloriesData(data) }
        } catch {
            trackerVM.addFood(item)
        }
    }

    private func addAIFoodToTracker() async {
        guard let resp = aiResponse, let macros = resp.macros else { return }
        let item = FoodItem(
            title: resp.productName ?? "AI Scan",
            subtitle: "AI Scan",
            calories: "\(Int(macros.calories ?? 0)) kcal",
            proteins: "\(macros.proteins ?? 0)g",
            fat: "\(macros.fats ?? 0)g",
            carbs: "\(macros.carbs ?? 0)g"
        )
        await addFoodToTracker(item)
    }

    private func startAIAnalysis(for item: FoodItem) async {
        isAnalyzing = true
        analysisFailed = false
        let queryText = item.ingredients.isNilOrEmpty
            ? "Product: \(item.title). Ingredients unknown, analyze based on general knowledge."
            : item.ingredients!

        // Build user profile JSON for AI
        let userProfileJson = await buildUserProfileJson()
        let productJson = buildProductJson(for: item)

        do {
            let response = try await AINetworkService.shared.analyzeIngredientsFull(
                ingredients: queryText,
                healthInfo: userProfileJson != nil ? "User health profile JSON:\n\(userProfileJson!)" : "General Analysis",
                productJson: productJson,
                userProfileJson: userProfileJson
            )
            aiResponse = response
            await saveProductScan(productName: item.title, response: response)
        } catch {
            analysisFailed = true
        }
        isAnalyzing = false
    }

    private func buildUserProfileJson() async -> String? {
        do {
            let resp = try await BackendUserService.shared.getUserDetails()
            if let data = resp.data {
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                if let jsonData = try? encoder.encode(data),
                   let str = String(data: jsonData, encoding: .utf8) {
                    return str
                }
            }
        } catch {}
        return nil
    }

    private func buildProductJson(for item: FoodItem) -> String? {
        var dict: [String: Any] = [:]
        dict["product_name"] = item.title
        dict["brands"] = item.subtitle ?? NSNull()
        dict["ingredients_text"] = item.ingredients ?? NSNull()
        dict["nutriscore_grade"] = item.grade ?? NSNull()
        var nutriments: [String: Any] = [:]
        nutriments["energy-kcal_100g"] = item.calories?.toCleanDouble() ?? 0
        nutriments["proteins_100g"] = item.proteins.toCleanDouble()
        nutriments["carbohydrates_100g"] = item.carbs.toCleanDouble()
        nutriments["fat_100g"] = item.fat.toCleanDouble()
        nutriments["sugars_100g"] = item.sugars?.toCleanDouble() ?? 0
        nutriments["fiber_100g"] = item.fiber?.toCleanDouble() ?? 0
        nutriments["sodium_100g"] = item.sodium?.toCleanDouble() ?? 0
        nutriments["cholesterol_100g"] = item.cholesterol?.toCleanDouble() ?? 0
        dict["nutriments"] = nutriments
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    private func saveProductScan(productName: String, response: AnalysisResponse) async {
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            guard let jsonData = try? encoder.encode(response),
                  let jsonObj = try? JSONSerialization.jsonObject(with: jsonData) else { return }
            let req = BackendCreateProductScanRequest(productName: productName, scanInformation: AnyCodable(jsonObj))
            if let scanId = currentScanId {
                _ = try await BackendUserService.shared.updateProductScan(id: scanId, req)
            } else {
                _ = try await BackendUserService.shared.createProductScan(req)
                await refreshScanId(productName: productName)
            }
        } catch {}
    }

    private func loadSavedProductScan(for item: FoodItem) async {
        isAnalyzing = true
        do {
            let resp = try await BackendUserService.shared.getProductScanByName(productName: item.title)
            if resp.success {
                if let savedResponse = extractAnalysisResponse(from: resp.data) {
                    aiResponse = savedResponse
                }
                currentScanId = extractScanId(from: resp.data)
            }
        } catch {}
        isAnalyzing = false
    }

    private func extractScanId(from data: AnyCodable?) -> Int? {
        guard let val = data?.value else { return nil }
        if let arr = val as? [[String: Any]], let first = arr.first {
            return first["id"] as? Int
        }
        if let dict = val as? [String: Any] {
            return dict["id"] as? Int
        }
        return nil
    }

    private func extractAnalysisResponse(from data: AnyCodable?) -> AnalysisResponse? {
        guard let val = data?.value else { return nil }
        var scanInfo: Any?
        if let arr = val as? [[String: Any]], let first = arr.first {
            scanInfo = first["scan_information"]
        } else if let dict = val as? [String: Any] {
            scanInfo = dict["scan_information"]
        }
        guard let si = scanInfo else { return nil }
        if let jsonData = try? JSONSerialization.data(withJSONObject: si) {
            return try? JSONDecoder().decode(AnalysisResponse.self, from: jsonData)
        }
        if let str = si as? String, let jsonData = str.data(using: .utf8) {
            return try? JSONDecoder().decode(AnalysisResponse.self, from: jsonData)
        }
        return nil
    }

    private func refreshScanId(productName: String) async {
        if let resp = try? await BackendUserService.shared.getProductScanByName(productName: productName) {
            currentScanId = extractScanId(from: resp.data)
        }
    }

    private func scaledVal(_ str: String) -> String {
        let unit = str.filter { !($0.isNumber || $0 == "." || $0 == ",") }.trimmingCharacters(in: .whitespaces)
        let val = str.toCleanDouble() * servingMultiplier
        return unit.isEmpty ? formatAmount(val) : "\(formatAmount(val)) \(unit)"
    }

    private func scaledInt(_ str: String?) -> Int {
        Int((str?.toCleanDouble() ?? 0) * servingMultiplier)
    }

    private func scaledDouble(_ str: String?) -> Double? {
        guard let s = str, !s.isEmpty else { return nil }
        return s.toCleanDouble() * servingMultiplier
    }

    private func formatAmount(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }

    private var currentGrade: String {
        if let resp = aiResponse {
            switch resp.healthScore ?? 0 {
            case 80...: return "A"
            case 60..<80: return "B"
            case 40..<60: return "C"
            default: return "E"
            }
        }
        return foodItem?.grade?.uppercased() ?? "B"
    }

    private var currentCalories: String {
        if let m = aiResponse?.macros { return "\(Int(m.calories ?? 0)) kcal" }
        return scaledVal(foodItem?.calories ?? "0")
    }

    private var currentProteins: Double {
        if let p = aiResponse?.macros?.proteins { return p }
        return (foodItem?.proteins.toCleanDouble() ?? 0) * servingMultiplier
    }

    private var currentCarbs: Double {
        if let c = aiResponse?.macros?.carbs { return c }
        return (foodItem?.carbs.toCleanDouble() ?? 0) * servingMultiplier
    }

    private var currentFat: Double {
        if let f = aiResponse?.macros?.fats { return f }
        return (foodItem?.fat.toCleanDouble() ?? 0) * servingMultiplier
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A": return Color(hex: "#2E7D32")
        case "B": return Color(hex: "#8BC34A")
        case "C": return Color(hex: "#FBC02D")
        case "D": return Color(hex: "#F57C00")
        case "E": return Color(hex: "#D32F2F")
        default: return .gray
        }
    }

    private func gradeLabel(_ grade: String) -> String {
        switch grade {
        case "A": return "Excellent"
        case "B": return "Good"
        case "C": return "Average"
        case "D": return "Poor"
        case "E": return "Bad"
        default: return "Unknown"
        }
    }

    // MARK: - Fav/resent

    private func checkFavoriteStatus(_ item: FoodItem) {
        let descriptor = FetchDescriptor<FavoriteProductEntity>(predicate: #Predicate { $0.id == item.title })
        isFavorite = (try? modelContext.fetch(descriptor).isEmpty == false) ?? false
    }

    private func toggleFavorite() {
        guard let item = foodItem else { return }
        if isFavorite {
            let descriptor = FetchDescriptor<FavoriteProductEntity>(predicate: #Predicate { $0.id == item.title })
            if let existing = try? modelContext.fetch(descriptor).first { modelContext.delete(existing) }
        } else {
            modelContext.insert(FavoriteProductEntity(from: item))
        }
        isFavorite.toggle()
        try? modelContext.save()
    }

    private func saveToRecent(_ item: FoodItem) {
        modelContext.insert(RecentProductEntity(from: item))
        try? modelContext.save()
    }
}

// MARK: - Sub-components

struct NutrientRow: View {
    let name: String
    let value: String
    var body: some View {
        HStack {
            Text(name).font(.subheadline).foregroundColor(.primary)
            Spacer()
            Text(value).font(.subheadline).fontWeight(.semibold)
        }
        .padding(.vertical, 10)
    }
}

struct MacroProgressItem: View {
    let title: String
    let value: Double
    let maxValue: Double
    let color: Color
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(color.opacity(0.2), lineWidth: 6)
                Circle().trim(from: 0, to: min(value / maxValue, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(String(format: "%.0fg", value)).font(.caption2).fontWeight(.bold)
            }
            .frame(width: 60, height: 60)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
