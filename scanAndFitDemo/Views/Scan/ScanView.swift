import SwiftUI
import PhotosUI

struct ScanView: View {
    @EnvironmentObject private var trackerVM: TrackerViewModel
    @StateObject private var viewModel = ScanViewModel()
    @State private var cameraCoordinator: CameraView.Coordinator?
    @State private var capturedForCamera: UIImage?
    @State private var showPhotosPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var navigateToResult = false
    @State private var analysisResult: AnalysisResponse?
    @State private var navigateToBrowse = false
    @State private var navigateToSearch = false
    @State private var showIngredientInput = false
    @State private var ingredientText = ""
    @State private var showProPage = false
    @State private var limitAlert: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview
                CameraRepresentable(capturedImage: $capturedForCamera, coordinator: $cameraCoordinator)
                    .ignoresSafeArea()

                VStack {
                    // Top bar
                    HStack {
                        Button { navigateToSearch = true } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.title2).foregroundColor(.white)
                                .padding(10).background(.ultraThinMaterial).cornerRadius(10)
                        }
                        Spacer()
                        // Scan limit badge
                        scanLimitBadge
                        Spacer()
                        Button { navigateToBrowse = true } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "square.grid.2x2")
                                Text("Browse")
                            }
                            .font(.subheadline).foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(.ultraThinMaterial).cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 60)

                    Spacer()

                    // Viewfinder frame
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                        .frame(width: 260, height: 260)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "viewfinder")
                                    .font(.system(size: 40)).foregroundColor(.white.opacity(0.5))
                                Text("Point at a product or label")
                                    .font(.caption).foregroundColor(.white.opacity(0.7))
                            }
                        )

                    Spacer()

                    // Loading
                    if case .analyzing = viewModel.scanState {
                        VStack(spacing: 8) {
                            ProgressView().tint(.white).scaleEffect(1.4)
                            Text("Analyzing… 30–40 sec")
                                .foregroundColor(.white).font(.subheadline)
                        }
                        .padding(.bottom, 20)
                    }

                    // Bottom controls
                    HStack(spacing: 36) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title).foregroundColor(.white)
                                .frame(width: 52, height: 52)
                                .background(.ultraThinMaterial).cornerRadius(14)
                        }

                        Button { cameraCoordinator?.capture() } label: {
                            ZStack {
                                Circle().fill(Color.white).frame(width: 72, height: 72)
                                Circle().stroke(Color.white.opacity(0.5), lineWidth: 3).frame(width: 82, height: 82)
                            }
                        }
                        .disabled(viewModel.scanState == .analyzing)

                        Button { showIngredientInput = true } label: {
                            Image(systemName: "text.cursor")
                                .font(.title).foregroundColor(.white)
                                .frame(width: 52, height: 52)
                                .background(.ultraThinMaterial).cornerRadius(14)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .onChange(of: capturedForCamera) { _, image in
                guard let image else { return }
                Task { await viewModel.analyzePhoto(image) }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await viewModel.analyzePhoto(image)
                    }
                }
            }
            .onChange(of: viewModel.scanState) { _, state in
                switch state {
                case .result(let response):
                    analysisResult = response
                    navigateToResult = true
                case .limitExceeded(let msg):
                    limitAlert = msg
                default: break
                }
            }
            .alert("Scan Error", isPresented: .init(
                get: { if case .error = viewModel.scanState { return true }; return false },
                set: { if !$0 { viewModel.reset() } }
            )) {
                Button("OK") { viewModel.reset() }
            } message: {
                if case .error(let msg) = viewModel.scanState { Text(msg) }
            }
            .alert("Scan Limit Reached", isPresented: Binding(
                get: { limitAlert != nil },
                set: { if !$0 { limitAlert = nil; viewModel.reset() } }
            )) {
                Button("Upgrade to Pro") { showProPage = true; viewModel.reset() }
                Button("Cancel", role: .cancel) { viewModel.reset() }
            } message: {
                Text(limitAlert ?? "You have used all your daily scans.")
            }
            .sheet(isPresented: $showIngredientInput) {
                IngredientInputSheet(text: $ingredientText) {
                    showIngredientInput = false
                    Task { await viewModel.analyzeIngredients(ingredientText) }
                }
            }
            .navigationDestination(isPresented: $navigateToResult) {
                if let result = analysisResult {
                    ProductDetailView(analysisResponse: result)
                        .environmentObject(trackerVM)
                        .onDisappear { viewModel.reset() }
                }
            }
            .navigationDestination(isPresented: $navigateToBrowse) {
                CategoriesView().environmentObject(trackerVM)
            }
            .navigationDestination(isPresented: $navigateToSearch) {
                SearchView().environmentObject(trackerVM)
            }
            .navigationDestination(isPresented: $showProPage) {
                ProSubscriptionView()
            }
        }
        .task { await viewModel.loadScanLimit() }
    }

//limit scan
    @ViewBuilder
    private var scanLimitBadge: some View {
        if let limit = viewModel.scanLimitData {
            let isUnlimited = limit.isUnlimited ?? false
            let remaining = limit.remaining ?? 0
            Button { showProPage = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: isUnlimited ? "infinity" : "camera.viewfinder")
                        .font(.caption)
                    if isUnlimited {
                        Text("Pro")
                            .font(.caption).fontWeight(.bold)
                    } else {
                        Text("\(remaining) left")
                            .font(.caption).fontWeight(.semibold)
                    }
                }
                .foregroundColor(isUnlimited ? Color(hex: "#FBBF24") : (remaining > 0 ? .white : .red))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
            }
        }
    }
}

struct IngredientInputSheet: View {
    @Binding var text: String
    let onAnalyze: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter product name or ingredients")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                TextEditor(text: $text)
                    .frame(height: 180)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .font(.body)
                Button {
                    guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onAnalyze()
                } label: {
                    Text("Analyze with AI")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(16)
                        .background(Color("AppGreen")).cornerRadius(14)
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(20)
            .navigationTitle("Type Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
//camera

private struct CameraRepresentable: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var coordinator: CameraView.Coordinator?

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onCapture = { image in DispatchQueue.main.async { capturedImage = image } }
        DispatchQueue.main.async { coordinator = context.coordinator.inner }
        return vc
    }
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var inner = CameraView.Coordinator()
    }
}

extension ScanState: Equatable {
    static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.analyzing, .analyzing): return true
        case (.result, .result), (.error, .error), (.limitExceeded, .limitExceeded): return true
        default: return false
        }
    }
}
