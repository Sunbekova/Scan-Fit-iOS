import Foundation
import Combine

@MainActor
final class UserProfileViewModel: ObservableObject {

    @Published var isLoading  = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published var username = ""
    @Published var email    = ""

    @Published var age      = ""
    @Published var gender   = "Male"
    @Published var height   = 170
    @Published var weight   = 70
    @Published var hasMeasure = false

    @Published var dietTypes:       [BackendDietType] = []
    @Published var dietaryPrefs:    [BackendDietType] = []
    @Published var healthConditions:[BackendDietType] = []
    @Published var diseases:        [BackendDisease]  = []
    @Published var diseaseLevels:   [BackendDiseaseLevel] = []

    @Published var weightGoal = ""
    @Published var targetWeight = 65
    @Published var weeklyChange = 0

    private let userSvc = BackendUserService.shared
    private let tokens  = TokenManager.shared


    func loadAll() async {
        isLoading = true
        defer { isLoading = false }

        async let meTask          = userSvc.getMe()
        async let measureTask     = (try? userSvc.getMeasure())
        async let dietTask        = (try? userSvc.getDietTypes())
        async let prefTask        = (try? userSvc.getDietaryPreferences())
        async let condTask        = (try? userSvc.getHealthConditions())
        async let diseaseTask     = (try? userSvc.getDiseases())
        async let levelTask       = (try? userSvc.getDiseaseLevels())
        async let weightMgmtTask  = (try? userSvc.getWeightManagement())

        do {
            let (me, measure, diet, prefs, conds, diseasesResp, levels, wm) =
                try await (meTask, measureTask, dietTask, prefTask, condTask, diseaseTask, levelTask, weightMgmtTask)

            if let userData = me.data {
                username = userData.username ?? ""
                email    = userData.email
            }

            if let m = measure?.data {
                age    = m.age ?? ""
                gender = m.gender ?? "Male"
                height = m.height ?? 170
                weight = m.weight ?? 70
                hasMeasure = true
            }

            dietTypes        = diet?.data ?? []
            dietaryPrefs     = prefs?.data ?? []
            healthConditions = conds?.data ?? []
            diseases         = diseasesResp?.data ?? []
            diseaseLevels    = levels?.data ?? []

            if let w = wm?.data {
                weightGoal    = w.goal ?? ""
                targetWeight  = w.targetWeight ?? 65
                weeklyChange  = w.weeklyWeightChange ?? 0
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Save/Update

    func saveMeasures(birthDate: String = "", bloodPressure: Int = 120,
                      cholesterol: Int = 180, dailyCaloriesGoal: Int = 2000,
                      dailyWaterGoal: Int = 8) async {
        isLoading = true
        defer { isLoading = false }

        guard let uid = tokens.userId else {
            errorMessage = "Not authenticated"
            return
        }

        do {
            if hasMeasure {
                let req = BackendUpdateUserMeasureRequest(
                    age: age, birthDate: birthDate, bloodPressure: bloodPressure,
                    bmi: calculateBMI(), cholesterol: cholesterol,
                    dailyCaloriesGoal: dailyCaloriesGoal, dailyWaterGoal: dailyWaterGoal,
                    gender: gender, height: height, weight: weight
                )
                _ = try await userSvc.updateMeasure(req)
            } else {
                let req = BackendUserMeasureRequest(
                    age: age, birthDate: birthDate, bloodPressure: bloodPressure,
                    bmi: calculateBMI(), cholesterol: cholesterol,
                    dailyCaloriesGoal: dailyCaloriesGoal, dailyWaterGoal: dailyWaterGoal,
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

    func toggleDietType(id: Int, isActive: Bool) async {
        do {
            _ = try await userSvc.updateDietType(id: id, isActive: isActive)
            if let idx = dietTypes.firstIndex(where: { $0.id == id }) {
                dietTypes[idx] = BackendDietType(
                    id: dietTypes[idx].id, name: dietTypes[idx].name,
                    isActive: isActive, category: dietTypes[idx].category
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: -Condition toggle

    func toggleHealthCondition(id: Int, isActive: Bool) async {
        do {
            _ = try await userSvc.updateHealthCondition(id: id, isActive: isActive)
            if let idx = healthConditions.firstIndex(where: { $0.id == id }) {
                healthConditions[idx] = BackendDietType(
                    id: healthConditions[idx].id, name: healthConditions[idx].name,
                    isActive: isActive, category: healthConditions[idx].category
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: -disease tog

    func toggleDisease(id: Int, diseaseLevelId: Int, isActive: Bool) async {
        do {
            _ = try await userSvc.updateDisease(id: id, diseaseLevelId: diseaseLevelId, isActive: isActive)
            if let idx = diseases.firstIndex(where: { $0.id == id }) {
                diseases[idx] = BackendDisease(
                    id: diseases[idx].id, code: diseases[idx].code,
                    name: diseases[idx].name, description: diseases[idx].description,
                    diseaseLevel: diseases[idx].diseaseLevel, isActive: isActive
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

    var activeHealthInfo: String {
        let activeConditions = healthConditions.filter(\.isActive).map(\.name)
        let activeDiseases   = diseases.filter(\.isActive).map(\.name)
        let all = activeConditions + activeDiseases
        return all.isEmpty ? "None" : all.joined(separator: ", ")
    }

    private func calculateBMI() -> Int {
        guard height > 0 else { return 22 }
        let heightM = Double(height) / 100.0
        return Int(Double(weight) / (heightM * heightM))
    }
}
