import SwiftUI
import PhotosUI

// MARK: - Compare Products View

struct CompareProductsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var imageA: UIImage?
    @State private var imageB: UIImage?
    @State private var pickerSlot: CompareSlot?
    @State private var showImageSourceSheet = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isComparing = false
    @State private var result: CompareProductsResponse?
    @State private var errorMessage: String?

    enum CompareSlot { case a, b }

    var canCompare: Bool { imageA != nil && imageB != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Image slots
                    HStack(spacing: 16) {
                        imageSlot(slot: .a, image: imageA, label: "Product A")
                        imageSlot(slot: .b, image: imageB, label: "Product B")
                    }
                    .padding(.horizontal)

                    // Compare button
                    Button {
                        Task { await runComparison() }
                    } label: {
                        HStack {
                            if isComparing {
                                ProgressView().tint(.white).padding(.trailing, 4)
                            }
                            Text(isComparing ? "Analyzing...".localized : "Compare Products".localized)
                                .font(.headline).foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity).padding(16)
                        .background(canCompare ? Color("AppGreen") : Color.gray.opacity(0.4))
                        .cornerRadius(14)
                    }
                    .disabled(!canCompare || isComparing)
                    .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error).font(.caption).foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    // Results
                    if let result = result {
                        CompareResultsView(result: result)
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Compare Products".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").foregroundColor(Color("AppGreen"))
                    }
                }
            }
            .confirmationDialog("Add Photo".localized, isPresented: $showImageSourceSheet) {
                Button("Camera".localized) { showCamera = true }
                Button("Photo Library".localized) { showPhotoPicker = true }
                Button("Cancel".localized, role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraImagePicker { img in
                    if let slot = pickerSlot {
                        switch slot {
                        case .a: imageA = img
                        case .b: imageB = img
                        }
                    }
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
            .onChange(of: photoPickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        await MainActor.run {
                            switch pickerSlot {
                            case .a: imageA = img
                            case .b: imageB = img
                            case nil: break
                            }
                        }
                    }
                    photoPickerItem = nil
                }
            }
        }
    }

    @ViewBuilder
    private func imageSlot(slot: CompareSlot, image: UIImage?, label: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
                    .frame(height: 160)

                if let img = image {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray)
                        Text("Tap to add".localized)
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .onTapGesture {
                pickerSlot = slot
                showImageSourceSheet = true
            }

            Text(label)
                .font(.subheadline).fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }

    private func runComparison() async {
        guard let imgA = imageA, let imgB = imageB else { return }
        isComparing = true
        errorMessage = nil
        result = nil
        defer { isComparing = false }

        let dataA = imgA.jpegData(compressionQuality: 0.75) ?? Data()
        let dataB = imgB.jpegData(compressionQuality: 0.75) ?? Data()

        // Build user info JSON
        let userInfo: String
        if let details = try? await BackendUserService.shared.getUserDetails(),
           let d = details.data,
           let json = try? JSONEncoder().encode(d),
           let str = String(data: json, encoding: .utf8) {
            userInfo = str
        } else {
            userInfo = "{}"
        }

        do {
            result = try await BackendUserService.shared.compareProductImages(imageA: dataA, imageB: dataB, userInfo: userInfo)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Compare Results

struct CompareResultsView: View {
    let result: CompareProductsResponse

    private var winnerColor: Color {
        switch result.winner?.uppercased() {
        case "A": return Color(hex: "#059669")
        case "B": return Color(hex: "#2563EB")
        default: return Color(hex: "#7C3AED")
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Winner banner
            VStack(spacing: 4) {
                let winner = result.winner?.uppercased() ?? "TIE"
                Text(winner == "TIE" ? "It's a Tie!" : "Winner 🏆".localized)
                    .font(.caption).fontWeight(.semibold).foregroundColor(.white.opacity(0.9))
                Text(winner == "TIE" ? "Both products are similar".localized
                     : (result.winnerName ?? (winner == "A" ? (result.nameA ?? "Product A") : (result.nameB ?? "Product B"))))
                    .font(.headline).fontWeight(.bold).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity).padding(16)
            .background(winnerColor).cornerRadius(14)

            // Score cards
            HStack(spacing: 12) {
                scoreCard(name: result.nameA ?? "Product A",
                          score: result.healthScoreA,
                          verdict: result.verdictA,
                          color: Color(hex: "#059669"))
                scoreCard(name: result.nameB ?? "Product B",
                          score: result.healthScoreB,
                          verdict: result.verdictB,
                          color: Color(hex: "#2563EB"))
            }

            // Recommendation
            if let rec = result.recommendation, !rec.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Recommendation".localized, systemImage: "lightbulb.fill")
                        .font(.subheadline).fontWeight(.semibold)
                    Text(rec).font(.body).foregroundColor(.secondary)
                }
                .padding(14)
                .background(Color(.systemGray6)).cornerRadius(12)
            }

            // Nutrient comparison table
            if let nutrients = result.nutrientComparison, !nutrients.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Nutrient Comparison".localized)
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.bottom, 8)
                    // Header
                    HStack {
                        Text("Nutrient".localized).font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                        Text("A").font(.caption).fontWeight(.bold).foregroundColor(.secondary).frame(width: 60, alignment: .center)
                        Text("B").font(.caption).fontWeight(.bold).foregroundColor(.secondary).frame(width: 60, alignment: .center)
                        Text("Best".localized).font(.caption).foregroundColor(.secondary).frame(width: 36, alignment: .center)
                    }
                    .padding(.vertical, 6)
                    Divider()
                    ForEach(nutrients) { row in
                        let better = row.better?.uppercased()
                        HStack {
                            Text(row.nutrient ?? "").font(.caption2).frame(maxWidth: .infinity, alignment: .leading)
                            Text(row.valueA ?? "—")
                                .font(.caption2)
                                .foregroundColor(better == "A" ? Color(hex: "#059669") : .primary)
                                .fontWeight(better == "A" ? .bold : .regular)
                                .frame(width: 60, alignment: .center)
                            Text(row.valueB ?? "—")
                                .font(.caption2)
                                .foregroundColor(better == "B" ? Color(hex: "#2563EB") : .primary)
                                .fontWeight(better == "B" ? .bold : .regular)
                                .frame(width: 60, alignment: .center)
                            Text(better == "A" ? "A" : better == "B" ? "B" : "=")
                                .font(.caption2).fontWeight(.bold)
                                .foregroundColor((better == "A" || better == "B") ? Color(hex: "#059669") : .secondary)
                                .frame(width: 36, alignment: .center)
                        }
                        .padding(.vertical, 6)
                        Divider()
                    }
                }
                .padding(14)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }

            // Risks A
            if let risksA = result.risksA, !risksA.isEmpty {
                risksCard(title: "Risks — \(result.nameA ?? "Product A")", risks: risksA, bgColor: Color(hex: "#FFF3E8"))
            }

            // Risks B
            if let risksB = result.risksB, !risksB.isEmpty {
                risksCard(title: "Risks — \(result.nameB ?? "Product B")", risks: risksB, bgColor: Color(hex: "#EFF6FF"))
            }
        }
        .padding(.horizontal)
    }

    private func scoreCard(name: String, score: Int?, verdict: String?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name).font(.caption).fontWeight(.semibold).lineLimit(1)
            Text("\(score ?? 0)")
                .font(.system(size: 32, weight: .bold)).foregroundColor(color)
            Text("/ 100").font(.caption2).foregroundColor(.secondary)
            if let v = verdict, !v.isEmpty {
                Text(v).font(.caption2).foregroundColor(.secondary).lineLimit(3)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6)).cornerRadius(12)
    }

    private func risksCard(title: String, risks: [AnalysisRisk], bgColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline).fontWeight(.semibold)
            ForEach(risks) { risk in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(risk.ingredient ?? "Issue")
                            .font(.caption).fontWeight(.semibold)
                        Spacer()
                        let sev = risk.severity?.lowercased() ?? "low"
                        Text(sev.capitalized)
                            .font(.caption2).fontWeight(.bold).foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(sev == "high" ? Color.red : sev == "medium" ? Color.orange : Color.blue)
                            .cornerRadius(6)
                    }
                    if let reason = risk.reason, !reason.isEmpty {
                        Text(reason).font(.caption2).foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
        .padding(12)
        .background(bgColor).cornerRadius(12)
    }
}

// MARK: - Camera Image Picker (UIKit wrapper)

struct CameraImagePicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage) -> Void
        init(onImage: @escaping (UIImage) -> Void) { self.onImage = onImage }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { onImage(img) }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
