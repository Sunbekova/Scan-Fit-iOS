import SwiftUI
import SwiftData

struct ProductDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var trackerVM: TrackerViewModel

    // Either from scan or from list
    let foodItem: FoodItem?
    let analysisResponse: AnalysisResponse?

    @State private var isFavorite = false
    @State private var aiResponse: AnalysisResponse?
    @State private var isAnalyzing = false
    @State private var analysisFailed = false

    init(foodItem: FoodItem? = nil, analysisResponse: AnalysisResponse? = nil) {
        self.foodItem = foodItem
        self.analysisResponse = analysisResponse
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Product image / header
                headerSection
                    .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 20) {
                    // Grade + score
                    gradeRow

                    // Macros
                    macroSection

                    // AI verdict
                    aiVerdictSection

                    // Nutrients table
                    nutrientsSection

                    // Add to tracker button
                    if let item = foodItem {
                        SFPrimaryButton(title: "Add to Today's Tracker") {
                            trackerVM.addFood(item)
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
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
            ToolbarItem(placement: .navigationBarTrailing) {
                if foodItem != nil {
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
                if analysisResponse == nil { Task { await runAIAnalysis(for: item) } }
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
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        placeholderHeader
                    }
                }
                .frame(height: 240)
                .clipped()
            } else {
                placeholderHeader.frame(height: 240)
            }

            LinearGradient(colors: [.clear, .black.opacity(0.6)],
                           startPoint: .top, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 4) {
                Text(foodItem?.subtitle ?? (analysisResponse != nil ? "SCANNER" : "PRODUCT"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                    .textCase(.uppercase)
                Text(foodItem?.title ?? "AI Analysis")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var placeholderHeader: some View {
        Rectangle()
            .fill(Color("AppGreen").opacity(0.15))
            .overlay(
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color("AppGreen").opacity(0.4))
            )
    }

    // MARK: - Grade Row

    private var gradeRow: some View {
        HStack(spacing: 16) {
            let grade = currentGrade
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(gradeColor(grade))
                    .frame(width: 52, height: 52)
                Text(grade)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Nutri-Score")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(gradeLabel(grade))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(gradeColor(grade))
            }
            Spacer()
            if let calories = currentCalories {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(calories)
                        .font(.system(size: 20, weight: .bold))
                    Text("per serving")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    // MARK: - Macros

    private var macroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macronutrients")
                .font(.headline)

            HStack(spacing: 12) {
                MacroProgressItem(title: "Protein", value: currentProteins, maxValue: 150, color: .blue)
                MacroProgressItem(title: "Carbs", value: currentCarbs, maxValue: 300, color: .orange)
                MacroProgressItem(title: "Fat", value: currentFat, maxValue: 70, color: .pink)
            }
        }
    }

    // MARK: - AI Verdict

    @ViewBuilder
    private var aiVerdictSection: some View {
        if isAnalyzing {
            HStack {
                ProgressView()
                Text("AI is analyzing ingredients...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        } else if let response = aiResponse {
            let score = response.healthScore ?? 0
            let isGood = score >= 40
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: isGood ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .foregroundColor(isGood ? .green : .red)
                    Text(isGood ? "✅ Safe to consume" : "❌ Use with caution")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("Score: \(score)/100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let verdict = response.verdict, !verdict.isEmpty {
                    Text(verdict)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Nutrients Table

    private var nutrientsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Nutrition Facts")
                .font(.headline)
                .padding(.bottom, 10)

            if let response = aiResponse, foodItem == nil {
                // AI-only risks list
                let risks = response.risks ?? []
                if risks.isEmpty {
                    NutrientRow(name: "Health Risks", value: "None detected ✨")
                } else {
                    ForEach(risks, id: \.self) { risk in
                        NutrientRow(name: "⚠️ Risk", value: risk)
                        Divider()
                    }
                }
            } else if let item = foodItem {
                Group {
                    NutrientRow(name: "Total Fat", value: item.fat)
                    Divider()
                    NutrientRow(name: "Protein", value: item.proteins)
                    Divider()
                    NutrientRow(name: "Total Carbohydrate", value: item.carbs)
                    Divider()
                    NutrientRow(name: "Sugar", value: item.sugars ?? "0g")
                    Divider()
                    NutrientRow(name: "Fiber", value: item.fiber ?? "0g")
                    Divider()
                    NutrientRow(name: "Sodium", value: item.sodium ?? "0mg")
                    Divider()
                    NutrientRow(name: "Cholesterol", value: item.cholesterol ?? "0mg")
                }
            }
        }
    }

    // MARK: - Helpers

    private var currentGrade: String {
        if let response = aiResponse {
            let score = response.healthScore ?? 0
            switch score {
            case 80...: return "A"
            case 60..<80: return "B"
            case 40..<60: return "C"
            default: return "E"
            }
        }
        return foodItem?.grade?.uppercased() ?? "B"
    }

    private var currentCalories: String? {
        if let m = aiResponse?.macros { return "\(Int(m.calories ?? 0)) kcal" }
        return foodItem?.calories
    }

    private var currentProteins: Double {
        if let p = aiResponse?.macros?.proteins { return p }
        return Double(foodItem?.proteins.filter { $0.isNumber || $0 == "." } ?? "0") ?? 0
    }

    private var currentCarbs: Double {
        if let c = aiResponse?.macros?.carbs { return c }
        return Double(foodItem?.carbs.filter { $0.isNumber || $0 == "." } ?? "0") ?? 0
    }

    private var currentFat: Double {
        if let f = aiResponse?.macros?.fats { return f }
        return Double(foodItem?.fat.filter { $0.isNumber || $0 == "." } ?? "0") ?? 0
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

    // MARK: - Favorites

    private func checkFavoriteStatus(_ item: FoodItem) {
        let descriptor = FetchDescriptor<FavoriteProductEntity>(
            predicate: #Predicate { $0.id == item.title }
        )
        isFavorite = (try? modelContext.fetch(descriptor).isEmpty == false) ?? false
    }

    private func toggleFavorite() {
        guard let item = foodItem else { return }
        if isFavorite {
            let descriptor = FetchDescriptor<FavoriteProductEntity>(
                predicate: #Predicate { $0.id == item.title }
            )
            if let existing = try? modelContext.fetch(descriptor).first {
                modelContext.delete(existing)
            }
        } else {
            let entity = FavoriteProductEntity(
                id: item.title,
                productName: item.title,
                brand: item.subtitle,
                imageURL: item.imageURL,
                calories: item.calories,
                grade: item.grade,
                ingredients: item.ingredients
            )
            modelContext.insert(entity)
        }
        isFavorite.toggle()
        try? modelContext.save()
    }

    // MARK: - Recent

    private func saveToRecent(_ item: FoodItem) {
        let entity = RecentProductEntity(
            id: item.title,
            title: item.title,
            subtitle: item.subtitle,
            imageURL: item.imageURL,
            calories: item.calories,
            grade: item.grade,
            ingredients: item.ingredients
        )
        modelContext.insert(entity)
        try? modelContext.save()
    }

    // MARK: - AI Analysis

    private func runAIAnalysis(for item: FoodItem) async {
        isAnalyzing = true
        let text = item.ingredients.isNilOrEmpty
            ? "Product: \(item.title). Ingredients unknown, analyze based on general knowledge."
            : item.ingredients!
        do {
            let response = try await NetworkService.shared.analyzeIngredients(ingredients: text, healthInfo: "General Analysis")
            await MainActor.run {
                aiResponse = response
                isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                isAnalyzing = false
                analysisFailed = true
            }
        }
    }
}

// MARK: - Sub-components

struct NutrientRow: View {
    let name: String
    let value: String
    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
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
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: min(value / maxValue, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(String(format: "%.0fg", value))
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .frame(width: 60, height: 60)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Extensions

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool { self?.isEmpty ?? true }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
