import SwiftUI
import AVFoundation
import UIKit
//camera coord
final class CameraCoordinator: NSObject, AVCapturePhotoCaptureDelegate {
    var onCapture: ((UIImage?) -> Void)?

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            onCapture?(nil); return
        }
        onCapture?(image)
    }
}

final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

final class CameraViewController: UIViewController {
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let coordinator = CameraCoordinator()
    var onCapture: ((UIImage?) -> Void)? {
        get { coordinator.onCapture }
        set { coordinator.onCapture = newValue }
    }

    private var previewView: CameraPreviewView!
    private var permissionLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPreview()
        checkPermissionAndConfigure()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.frame = view.bounds
        previewView.previewLayer.frame = view.bounds
        permissionLabel?.frame = view.bounds
    }

    private func setupPreview() {
        previewView = CameraPreviewView()
        previewView.previewLayer.videoGravity = .resizeAspectFill
        previewView.previewLayer.session = session
        view.addSubview(previewView)
    }

    private func checkPermissionAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.configureSession() }
                    else { self?.showPermissionDeniedUI() }
                }
            }
        default:
            showPermissionDeniedUI()
        }
    }

    private func showPermissionDeniedUI() {
        let label = UILabel()
        label.text = "Camera access denied.\nGo to Settings → Privacy → Camera\nand enable access for ScanFit."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 15)
        view.addSubview(label)
        permissionLabel = label
    }

    private func configureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input  = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)
            if self.session.canAddOutput(self.photoOutput) { self.session.addOutput(self.photoOutput) }
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: coordinator)
    }

    func stopSession() { if session.isRunning { session.stopRunning() } }
    func startSession() { if !session.isRunning { DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() } } }
}

// MARK: - SwiftUI Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onCapture = { image in DispatchQueue.main.async { capturedImage = image } }
        context.coordinator.vc = vc
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        weak var vc: CameraViewController?
        func capture() { vc?.capturePhoto() }
    }
}
struct CameraPermissionView: View {
    @State private var status: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

    var body: some View {
        switch status {
        case .authorized:
            EmptyView()
        case .notDetermined:
            Button("Allow Camera Access") {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        status = granted ? .authorized : .denied
                    }
                }
            }
            .padding()
        default:
            VStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary)
                Text("Camera Access Required")
                    .font(.headline)
                Text("To scan food products, please allow camera access in Settings.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .padding(.horizontal, 32).padding(.vertical, 12)
                .background(Color("AppGreen"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(32)
        }
    }
}
