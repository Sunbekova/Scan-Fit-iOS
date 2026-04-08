import SwiftUI
import PhotosUI

struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()
    @State private var cameraCoordinator: CameraView.Coordinator?
    @State private var capturedForCamera: UIImage?
    @State private var showPhotosPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var navigateToResult = false
    @State private var analysisResult: AnalysisResponse?
    @State private var navigateToBrowse = false
    @State private var navigateToSearch = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview
                CameraRepresentable(capturedImage: $capturedForCamera,
                                    coordinator: $cameraCoordinator)
                    .ignoresSafeArea()

                // Overlay UI
                VStack {
                    // Top bar
                    HStack {
                        Button { navigateToSearch = true } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                        }
                        Spacer()
                        Button { navigateToBrowse = true } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "square.grid.2x2")
                                Text("Browse")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    Spacer()

                    // Viewfinder frame
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                        .frame(width: 260, height: 260)
                        .overlay(
                            Image(systemName: "viewfinder")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.5))
                        )

                    Spacer()

                    // Status / loading
                    if case .analyzing = viewModel.scanState {
                        VStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.4)
                            Text("Analyzing... 30-40 sec")
                                .foregroundColor(.white)
                                .font(.subheadline)
                        }
                        .padding(.bottom, 20)
                    }

                    // Bottom controls
                    HStack(spacing: 40) {
                        // Gallery picker
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 52, height: 52)
                                .background(.ultraThinMaterial)
                                .cornerRadius(14)
                        }

                        // Capture button
                        Button {
                            cameraCoordinator?.capture()
                        } label: {
                            ZStack {
                                Circle().fill(Color.white).frame(width: 72, height: 72)
                                Circle().stroke(Color.white.opacity(0.5), lineWidth: 3).frame(width: 82, height: 82)
                            }
                        }
                        .disabled(viewModel.scanState == .analyzing)

                        // Placeholder for symmetry
                        Color.clear.frame(width: 52, height: 52)
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
                if case .result(let response) = state {
                    analysisResult = response
                    navigateToResult = true
                }
            }
            .alert("Scan Error", isPresented: .init(
                get: { if case .error = viewModel.scanState { return true }; return false },
                set: { if !$0 { viewModel.reset() } }
            )) {
                Button("OK") { viewModel.reset() }
            } message: {
                if case .error(let msg) = viewModel.scanState {
                    Text(msg)
                }
            }
            .navigationDestination(isPresented: $navigateToResult) {
                if let result = analysisResult {
                    ProductDetailView(analysisResponse: result)
                        .onDisappear { viewModel.reset() }
                }
            }
            .navigationDestination(isPresented: $navigateToBrowse) { CategoriesView() }
            .navigationDestination(isPresented: $navigateToSearch) { SearchView() }
        }
    }
}

// MARK: - Thin representable that exposes coordinator

private struct CameraRepresentable: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var coordinator: CameraView.Coordinator?

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onCapture = { image in
            DispatchQueue.main.async { capturedImage = image }
        }
        DispatchQueue.main.async { coordinator = context.coordinator.inner }
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var inner = CameraView.Coordinator()
    }
}

extension ScanViewModel {
    static var analyzing: Bool {
        false
    }
}

extension ScanState: Equatable {
    static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.analyzing, .analyzing): return true
        case (.result, .result), (.error, .error): return true
        default: return false
        }
    }
}
