import SwiftUI
import SwiftData

struct ProductDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var trackerVM: TrackerViewModel

    let foodItem: FoodItem?
    let analysisResponse: AnalysisResponse?

    @State var isFavorite = false
    @State var aiResponse: AnalysisResponse?
    @State var isAnalyzing = false
    @State var analysisFailed = false
    @State var servingMultiplier: Double = 1.0
    @State var currentScanId: Int? = nil

    private var hasProductDetails: Bool { foodItem != nil }
    let portionValues: [Double] = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0]

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
                isFavorite = LocalStorageService.isFavorite(id: item.id, context: modelContext)
                LocalStorageService.saveRecent(item: item, context: modelContext)
                if analysisResponse == nil {
                    Task { await loadSavedProductScan(for: item) }}
            }
            if let resp = analysisResponse {aiResponse = resp}
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

}
