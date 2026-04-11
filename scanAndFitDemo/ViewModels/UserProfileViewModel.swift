import Foundation
import Combine

@MainActor
final class UserProfileViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published var username = ""
    @Published var email = ""

    @Published var age = ""
    @Published var gender = ""
    @Published var height = 0
    @Published var weight = 0
    @Published var birthDate = ""
    @Published var bloodPressure = 0
    @Published var cholesterol = 0
    @Published var bmi = 0
    @Published var dailyCaloriesGoal = 2000
    @Published var dailyWaterGoal = 8
    @Published var hasMeasure = false

    @Published var dietTypes: [BackendDietType] = []
    @Published var dietaryPrefs: [BackendDietType] = []
    @Published var healthConditions: [BackendDietType] = []
    @Published var diseases: [BackendDisease] = []
    @Published var diseaseLevels: [BackendDiseaseLevel] = []

    @Published var weightGoal = ""
    @Published var targetWeight = 0
    @Published var targetDate = ""
    @Published var weeklyChange = 1

    var bmiString: String {
        guard height > 0, weight > 0 else { return "—" }
        let hm = Double(height) / 100.0
        let val = Double(weight) / (hm * hm)
        return String(format: "%.1f", val)
    }

    var targetDateDisplay: String {
        guard !targetDate.isEmpty else { return "Not set" }
        let inFmt = DateFormatter(); inFmt.dateFormat = "yyyy-MM-dd"
        let outFmt = DateFormatter(); outFmt.dateFormat = "dd MMM yyyy"
        if let d = inFmt.date(from: targetDate) { return outFmt.string(from: d) }
        return targetDate
    }

    private let userSvc = BackendUserService.shared
    private let tokens = TokenManager.shared

    func loadAll() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        async let meTask = userSvc.getMe()
        async let measureTask = (try? userSvc.getMeasure())
        async let dietTask = (try? userSvc.getDietTypes())
        async let prefTask = (try? userSvc.getDietaryPreferences())
        async let condTask = (try? userSvc.getHealthConditions())
        async let diseaseTask = (try? userSvc.getDiseases())
        async let levelTask = (try? userSvc.getDiseaseLevels())
        async let weightMgmtTask = (try? userSvc.getWeightManagement())

        do {
            let (me, measure, diet, prefs, conds, diseasesResp, levels, wm) =
                try await (meTask, measureTask, dietTask, prefTask, condTask, diseaseTask, levelTask, weightMgmtTask)

            if let userData = me.data {
                username = userData.username ?? ""
                email = userData.email
            }

            if let m = measure?.data {
                age = m.age ?? ""
                gender = m.gender ?? ""
                height = m.height ?? 0
                weight = m.weight ?? 0
                birthDate = m.birthDate ?? ""
                bloodPressure = m.bloodPressure ?? 0
                cholesterol = m.cholesterol ?? 0
                bmi = m.bmi ?? 0
                dailyCaloriesGoal = m.dailyCaloriesGoal ?? 2000
                dailyWaterGoal = m.dailyWaterGoal ?? 8
                hasMeasure = true
            }

            dietTypes = diet?.data ?? []
            dietaryPrefs = prefs?.data ?? []
            healthConditions = conds?.data ?? []
            diseases = diseasesResp?.data ?? []
            diseaseLevels = levels?.data ?? []

            if let w = wm?.data {
                weightGoal = w.goal ?? ""
                targetWeight = w.targetWeight ?? 0
                targetDate = w.targetDate ?? ""
                weeklyChange = w.weeklyWeightChange ?? 1
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveMeasures(customBirthDate: String? = nil) async {
        isLoading = true; defer { isLoading = false }
        guard let uid = tokens.userId else { errorMessage = "Not authenticated"; return }
        let finalBirthDate = customBirthDate ?? birthDate
        let bmiVal = calculateBMI()
        let ageStr = calculateAge(from: finalBirthDate)
        do {
            if hasMeasure {
                let req = BackendUpdateUserMeasureRequest(
                    age: ageStr, birthDate: finalBirthDate,
                    bloodPressure: bloodPressure, bmi: bmiVal, cholesterol: cholesterol,
                    dailyCaloriesGoal: dailyCaloriesGoal, dailyWaterGoal: dailyWaterGoal,
                    gender: gender, height: height, weight: weight
                )
                let resp = try await userSvc.updateMeasure(req)
                if let d = resp.data { applyMeasureData(d) }
            } else {
                let req = BackendUserMeasureRequest(
                    age: ageStr, birthDate: finalBirthDate,
                    bloodPressure: bloodPressure, bmi: bmiVal, cholesterol: cholesterol,
                    dailyCaloriesGoal: dailyCaloriesGoal, dailyWaterGoal: dailyWaterGoal,
                    gender: gender, height: height, userId: uid, weight: weight
                )
                let resp = try await userSvc.createMeasure(req)
                if let d = resp.data { applyMeasureData(d); hasMeasure = true }
            }
            successMessage = "Saved"
        } catch { errorMessage = error.localizedDescription }
    }

    private func applyMeasureData(_ d: BackendUserMeasureData) {
        age = d.age ?? ""
        gender = d.gender ?? gender
        height = d.height ?? height
        weight = d.weight ?? weight
        birthDate = d.birthDate ?? birthDate
        bloodPressure = d.bloodPressure ?? bloodPressure
        cholesterol = d.cholesterol ?? cholesterol
        bmi = d.bmi ?? bmi
        dailyCaloriesGoal = d.dailyCaloriesGoal ?? dailyCaloriesGoal
        dailyWaterGoal = d.dailyWaterGoal ?? dailyWaterGoal
    }

    // MARK: - Togg

    func toggleDietType(_ item: BackendDietType) async {
        let newActive = !item.isActive
        do {
            _ = try await userSvc.updateDietType(id: item.id, isActive: newActive)
            if let idx = dietTypes.firstIndex(where: { $0.id == item.id }) {
                dietTypes[idx] = BackendDietType(id: item.id, name: item.name, isActive: newActive, category: item.category)
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func toggleDietaryPreference(_ item: BackendDietType) async {
        let newActive = !item.isActive
        do {
            _ = try await userSvc.updateDietaryPreference(id: item.id, isActive: newActive)
            if let idx = dietaryPrefs.firstIndex(where: { $0.id == item.id }) {
                dietaryPrefs[idx] = BackendDietType(id: item.id, name: item.name, isActive: newActive, category: item.category)
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func toggleHealthCondition(_ item: BackendDietType) async {
        let newActive = !item.isActive
        do {
            _ = try await userSvc.updateHealthCondition(id: item.id, isActive: newActive)
            if let idx = healthConditions.firstIndex(where: { $0.id == item.id }) {
                healthConditions[idx] = BackendDietType(id: item.id, name: item.name, isActive: newActive, category: item.category)
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func toggleDisease(_ item: BackendDisease, levelId: Int, isActive: Bool) async {
        let isVip = TokenManager.shared.userRole == "vip"
        if !isVip && isActive && !item.isActive {
            let activeCount = diseases.filter(\.isActive).count
            if activeCount >= 3 { errorMessage = "Basic users can activate up to 3 diseases"; return }
        }
        do {
            _ = try await userSvc.updateDisease(id: item.id, diseaseLevelId: levelId, isActive: isActive)
            if let idx = diseases.firstIndex(where: { $0.id == item.id }) {
                diseases[idx] = BackendDisease(id: item.id, code: item.code, name: item.name,
                    description: item.description, diseaseLevel: item.diseaseLevel, isActive: isActive)
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func saveWeightManagement() async {
        isLoading = true; defer { isLoading = false }
        do {
            let normalizedDate = targetDate.isEmpty ? nil : targetDate
            let req = BackendUpdateWeightManagementRequest(
                goal: weightGoal.isEmpty ? nil : weightGoal,
                targetDate: normalizedDate,
                targetWeight: targetWeight > 0 ? targetWeight : nil,
                weeklyWeightChange: weeklyChange
            )
            _ = try await userSvc.updateWeightManagement(req)
            successMessage = "Weight management updated"
        } catch { errorMessage = error.localizedDescription }
    }

    func refreshTodayCalories() async {
        do {
            _ = try await userSvc.refreshTodayCalories()
            successMessage = "Calories refreshed"
        } catch { errorMessage = error.localizedDescription }
    }

    var healthInfoForAI: String {
        let active = healthConditions.filter(\.isActive).map(\.name)
            + diseases.filter(\.isActive).map(\.name)
        return active.isEmpty ? "None reported" : active.joined(separator: ", ")
    }

    private func calculateBMI() -> Int {
        guard height > 0 else { return 22 }
        let hm = Double(height) / 100.0
        return Int(Double(weight) / (hm * hm))
    }

    private func calculateAge(from dateStr: String) -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        guard let dob = fmt.date(from: dateStr) else { return "0" }
        let comps = Calendar.current.dateComponents([.year], from: dob, to: Date())
        return "\(comps.year ?? 0)"
    }
}
