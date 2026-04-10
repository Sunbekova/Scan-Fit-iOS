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
    @Published var gender = "Male"
    @Published var height = 170
    @Published var weight = 70
    @Published var birthDate = ""
    @Published var hasMeasure = false

    @Published var dietTypes: [BackendDietType] = []
    @Published var dietaryPrefs: [BackendDietType] = []
    @Published var healthConditions:[BackendDietType] = []
    @Published var diseases: [BackendDisease] = []
    @Published var diseaseLevels: [BackendDiseaseLevel] = []

    @Published var weightGoal = ""
    @Published var targetWeight = 65
    @Published var weeklyChange = 0

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
                gender = m.gender ?? "Male"
                height = m.height ?? 170
                weight = m.weight ?? 70
                birthDate = m.birthDate ?? ""
                hasMeasure = true
            }

            dietTypes = diet?.data ?? []
            dietaryPrefs = prefs?.data ?? []
            healthConditions = conds?.data ?? []
            diseases = diseasesResp?.data ?? []
            diseaseLevels = levels?.data ?? []

            if let w = wm?.data {
                weightGoal = w.goal ?? ""
                targetWeight = w.targetWeight ?? 65
                weeklyChange = w.weeklyWeightChange ?? 0
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Save/Update

    func saveMeasures(customBirthDate: String? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let uid = tokens.userId else {
            errorMessage = "Not authenticated"
            return
        }

        let finalBirthDate = customBirthDate ?? self.birthDate
        let bmiValue = calculateBMI()

        do {
            if hasMeasure {
                let req = BackendUpdateUserMeasureRequest(
                    age: age, birthDate: finalBirthDate, bloodPressure: 120,
                    bmi: bmiValue, cholesterol: 180,
                    dailyCaloriesGoal: 2000, dailyWaterGoal: 8,
                    gender: gender, height: height, weight: weight
                )
                _ = try await userSvc.updateMeasure(req)
            } else {
                let req = BackendUserMeasureRequest(
                    age: age, birthDate: finalBirthDate, bloodPressure: 120,
                    bmi: bmiValue, cholesterol: 180,
                    dailyCaloriesGoal: 2000, dailyWaterGoal: 8,
                    gender: gender, height: height, userId: uid, weight: weight
                )
                _ = try await userSvc.createMeasure(req)
                hasMeasure = true
            }
            successMessage = "Profile saved successfully"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: -Diet toggle

    func toggleDietType(_ item: BackendDietType) async {
        let newActive = !item.isActive
        do {
            _ = try await userSvc.updateDietType(id: item.id, isActive: newActive)
            if let idx = dietTypes.firstIndex(where: { $0.id == item.id }) {
                dietTypes[idx] = BackendDietType(
                    id: item.id, name: item.name,
                    isActive: newActive, category: item.category
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleHealthCondition(_ item: BackendDietType) async {
        let newActive = !item.isActive
        do {
            _ = try await userSvc.updateHealthCondition(id: item.id, isActive: newActive)
            if let idx = healthConditions.firstIndex(where: { $0.id == item.id }) {
                healthConditions[idx] = BackendDietType(
                    id: item.id, name: item.name,
                    isActive: newActive, category: item.category
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleDisease(_ item: BackendDisease, levelId: Int) async {
        let newActive = !item.isActive
        do {
            _ = try await userSvc.updateDisease(id: item.id, diseaseLevelId: levelId, isActive: newActive)
            if let idx = diseases.firstIndex(where: { $0.id == item.id }) {
                diseases[idx] = BackendDisease(
                    id: item.id, code: item.code,
                    name: item.name, description: item.description,
                    diseaseLevel: item.diseaseLevel, isActive: newActive
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleDietaryPreference(_ item: BackendDietType) async {
        let newActive = !item.isActive
        do {
            _ = try await userSvc.updateDietaryPreference(id: item.id, isActive: newActive)
            if let idx = dietaryPrefs.firstIndex(where: { $0.id == item.id }) {
                dietaryPrefs[idx] = BackendDietType(
                    id: item.id,
                    name: item.name,
                    isActive: newActive,
                    category: item.category
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }


    func saveWeightManagement() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let req = BackendUpdateWeightManagementRequest(
                goal: weightGoal.isEmpty ? nil : weightGoal,
                targetDate: nil,
                targetWeight: targetWeight,
                weeklyWeightChange: weeklyChange
            )
            _ = try await userSvc.updateWeightManagement(req)
            successMessage = "Weight goal saved"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var healthInfoForAI: String {
        let activeConditions = healthConditions.filter(\.isActive).map(\.name)
        let activeDiseases = diseases.filter(\.isActive).map(\.name)
        
        let all = activeConditions + activeDiseases
        return all.isEmpty ? "None reported" : all.joined(separator: ", ")
    }
    private func calculateBMI() -> Int {
        guard height > 0 else { return 22 }
        let heightM = Double(height) / 100.0
        return Int(Double(weight) / (heightM * heightM))
    }
}
