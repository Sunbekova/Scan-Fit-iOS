// productNetwork
import SwiftUI

extension ProductDetailView {
    // MARK: - +backend
    
    func addFoodToTracker(_ item: FoodItem) async {
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
            vitaminB6: scaledDouble(item.vitaminB6),
            vitaminB9: scaledDouble(item.vitaminB9),
            vitaminB12: scaledDouble(item.vitaminB12),
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
            vitaminA: scaledDouble(item.vitaminA),vitaminB6: scaledDouble(item.vitaminB6),
            vitaminB9: scaledDouble(item.vitaminB9), vitaminB12: scaledDouble(item.vitaminB12),
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
    
    func addAIFoodToTracker() async {
        guard let resp = aiResponse, let macros = resp.macros else { return }
        let eatReq = BackendCreateUserDailyEatRequest(
            calorie: Int(macros.calories ?? 0),
            carbohydrate: Int(macros.carbs ?? 0),
            cholesterol: Int(macros.cholesterol ?? 0),
            fats: Int(macros.resolvedFat ?? 0),
            fiber: Int(macros.fiber ?? 0),
            portion: 1.0,
            productName: resp.productName ?? "AI Scan",
            protein: Int(macros.proteins ?? 0),
            sodium: Int(macros.sodium ?? 0),
            sugar: Int(macros.sugar ?? 0),
            vitaminA: macros.vitaminA,
            vitaminB6: macros.vitaminB6,
            vitaminB9: macros.vitaminB9,
            vitaminB12: macros.vitaminB12,
            vitaminC: macros.vitaminC,
            vitaminD: macros.vitaminD,
            vitaminE: macros.vitaminE
        )
        let day = trackerVM.selectedDayString
        let calReq = BackendUpdateUserCaloriesRequest(
            calories: Int(macros.calories ?? 0),
            carbs: Int(macros.carbs ?? 0),
            fat: Int(macros.resolvedFat ?? 0),
            proteins: Int(macros.proteins ?? 0),
            fiber: Int(macros.fiber ?? 0),
            sodium: Int(macros.sodium ?? 0),
            sugar: Int(macros.sugar ?? 0),
            cholesterol: Int(macros.cholesterol ?? 0),
            vitaminA: macros.vitaminA,
            vitaminB6: macros.vitaminB6,
            vitaminB9: macros.vitaminB9,
            vitaminB12: macros.vitaminB12,
            vitaminC: macros.vitaminC,
            vitaminD: macros.vitaminD,
            vitaminE: macros.vitaminE
        )
        do {
            _ = try await BackendUserService.shared.createUserDailyEat(eatReq)
            let trackResp = try await BackendUserService.shared.updateUserCalories(day: day, req: calReq)
            if trackResp.success, let data = trackResp.data { trackerVM.applyCaloriesData(data) }
        } catch {
            // Fallback: update local tracker only
            let item = FoodItem(
                title: resp.productName ?? "AI Scan", subtitle: "AI Scan",
                calories: "\(Int(macros.calories ?? 0)) kcal",
                proteins: "\(macros.proteins ?? 0)g",
                fat: "\(macros.resolvedFat ?? 0)g",
                carbs: "\(macros.carbs ?? 0)g"
            )
            trackerVM.addFood(item)
        }
    }
    
    func startAIAnalysis(for item: FoodItem) async {
        isAnalyzing = true
        analysisFailed = false
        let queryText = item.ingredients.isNilOrEmpty
            ? "Product: \(item.title). Ingredients unknown, analyze based on general knowledge."
            : item.ingredients!

        let userProfileJson = await buildUserProfileJson()
        let productJson = buildProductJson(for: item)
        let healthInfo = userProfileJson != nil
            ? "User health profile JSON:\n\(userProfileJson!)"
            : "General Analysis"

        do {
            let response = try await AINetworkService.shared.analyzeIngredientsFull(
                ingredients: queryText,
                healthInfo: healthInfo,
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

    func buildUserProfileJson() async -> String? {
        do {
            let resp = try await BackendUserService.shared.getUserDetails()
            if let data = resp.data {
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                if let jsonData = try? encoder.encode(data),
                   let str = String(data: jsonData, encoding: .utf8) { return str }
            }
        } catch {}
        return nil
    }
    
    func buildProductJson(for item: FoodItem) -> String? {
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
    
    func saveProductScan(productName: String, response: AnalysisResponse) async {
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
    
    func loadSavedProductScan(for item: FoodItem) async {
        isAnalyzing = true
        do {
            let resp = try await BackendUserService.shared.getProductScanByName(productName: item.title)
            if resp.success {
                if let savedResponse = extractAnalysisResponse(from: resp.data) {aiResponse = savedResponse}
                currentScanId = extractScanId(from: resp.data)
            }
        } catch {}
        isAnalyzing = false
    }
    
    func refreshScanId(productName: String) async {
        if let resp = try? await BackendUserService.shared.getProductScanByName(productName: productName) {
            currentScanId = extractScanId(from: resp.data)
        }
    }
}
