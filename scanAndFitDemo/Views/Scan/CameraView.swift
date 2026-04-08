import SwiftUI
import AVFoundation
import UIKit

// MARK: - Camera Coordinator

final class CameraCoordinator: NSObject, AVCapturePhotoCaptureDelegate {
    var onCapture: ((UIImage?) -> Void)?

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            onCapture?(nil)
            return
        }
        onCapture?(image)
    }
}

// MARK: - Camera Preview UIView

final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// MARK: - Camera UIViewController

final class CameraViewController: UIViewController {
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let coordinator = CameraCoordinator()
    var onCapture: ((UIImage?) -> Void)? {
        get { coordinator.onCapture }
        set { coordinator.onCapture = newValue }
    }

    private var previewView: CameraPreviewView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPreview()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in self?.configureSession() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.frame = view.bounds
        previewView.previewLayer.frame = view.bounds
    }

    private func setupPreview() {
        previewView = CameraPreviewView()
        previewView.previewLayer.videoGravity = .resizeAspectFill
        previewView.previewLayer.session = session
        view.addSubview(previewView)
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration(); return
        }
        session.addInput(input)
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        session.commitConfiguration()
        session.startRunning()
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: coordinator)
    }

    func stopSession() { session.stopRunning() }
    func startSession() { if !session.isRunning { session.startRunning() } }
}

// MARK: - SwiftUI Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onCapture = { image in
            DispatchQueue.main.async { capturedImage = image }
        }
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
