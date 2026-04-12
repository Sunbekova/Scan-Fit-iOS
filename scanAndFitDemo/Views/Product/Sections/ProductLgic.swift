//product logic
import SwiftUI

extension ProductDetailView{
    
    func extractScanId(from data: AnyCodable?) -> Int? {
        guard let val = data?.value else { return nil }
        if let arr = val as? [[String: Any]], let first = arr.first {
            return first["id"] as? Int
        }
        if let dict = val as? [String: Any] {
            return dict["id"] as? Int
        }
        return nil
    }
    
    func extractAnalysisResponse(from data: AnyCodable?) -> AnalysisResponse? {
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
    
    func scaledVal(_ str: String) -> String {
        let unit = str.filter { !($0.isNumber || $0 == "." || $0 == ",") }.trimmingCharacters(in: .whitespaces)
        let val = str.toCleanDouble() * servingMultiplier
        return unit.isEmpty ? formatAmount(val) : "\(formatAmount(val)) \(unit)"
    }

    func scaledInt(_ str: String?) -> Int {
        Int((str?.toCleanDouble() ?? 0) * servingMultiplier)
    }

    func scaledDouble(_ str: String?) -> Double? {
        guard let s = str, !s.isEmpty else { return nil }
        return s.toCleanDouble() * servingMultiplier
    }

    func formatAmount(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }

    var currentGrade: String {
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

    var currentCalories: String {
        if let m = aiResponse?.macros { return "\(Int(m.calories ?? 0)) kcal" }
        return scaledVal(foodItem?.calories ?? "0")
    }

    var currentProteins: Double {
        if let p = aiResponse?.macros?.proteins { return p }
        return (foodItem?.proteins.toCleanDouble() ?? 0) * servingMultiplier
    }

    var currentCarbs: Double {
        if let c = aiResponse?.macros?.carbs { return c }
        return (foodItem?.carbs.toCleanDouble() ?? 0) * servingMultiplier
    }

    var currentFat: Double {
        if let f = aiResponse?.macros?.fats { return f }
        return (foodItem?.fat.toCleanDouble() ?? 0) * servingMultiplier
    }

    func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A": return Color(hex: "#2E7D32")
        case "B": return Color(hex: "#8BC34A")
        case "C": return Color(hex: "#FBC02D")
        case "D": return Color(hex: "#F57C00")
        case "E": return Color(hex: "#D32F2F")
        default: return .gray
        }
    }

    func gradeLabel(_ grade: String) -> String {
        switch grade {
        case "A": return "Excellent"
        case "B": return "Good"
        case "C": return "Average"
        case "D": return "Poor"
        case "E": return "Bad"
        default: return "Unknown"
        }
    }
    
    func toggleFavorite() {
            guard let item = foodItem else { return }
            LocalStorageService.toggleFavorite(item: item, context: modelContext)
            isFavorite.toggle()
        }
}
