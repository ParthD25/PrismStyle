import SwiftUI
import AVFoundation
import Combine
import UIKit

/// Enhanced camera view that can capture multiple outfit photos for AI analysis
struct EnhancedCameraBurstView: View {
    let captureMode: CaptureMode
    let countdownSeconds: Int
    let burstCount: Int
    let totalOutfitsToCapture: Int
    let onCancel: () -> Void
    let onCapturedBest: (UIImage) -> Void
    let onCapturedMultiple: ([UIImage]) -> Void

    @State private var remaining: Int
    @State private var currentPhase: CapturePhase = .countdown
    @State private var capturedImages: [UIImage] = []
    @State private var currentOutfitNumber = 1
    
    @StateObject private var controller = EnhancedCameraBurstController()

    enum CaptureMode {
        case single      // Capture one best photo
        case multiple    // Capture multiple outfit photos
    }
    
    enum CapturePhase {
        case countdown
        case capturing
        case reviewing
    }

    init(
        captureMode: CaptureMode = .single,
        countdownSeconds: Int = 7,
        burstCount: Int = 5,
        totalOutfitsToCapture: Int = 3,
        onCancel: @escaping () -> Void,
        onCapturedBest: @escaping (UIImage) -> Void,
        onCapturedMultiple: @escaping ([UIImage]) -> Void
    ) {
        self.captureMode = captureMode
        self.countdownSeconds = min(10, max(5, countdownSeconds))
        self.burstCount = min(8, max(3, burstCount))
        self.totalOutfitsToCapture = totalOutfitsToCapture
        self.onCancel = onCancel
        self.onCapturedBest = onCapturedBest
        self.onCapturedMultiple = onCapturedMultiple
        self._remaining = State(initialValue: min(10, max(5, countdownSeconds)))
    }

    var body: some View {
        ZStack {
            CameraPreview(controller: controller)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                    
                    if captureMode == .multiple {
                        Text("\(currentOutfitNumber)/\(totalOutfitsToCapture)")
                            .font(.headline)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                .padding()

                Spacer()

                VStack(spacing: 20) {
                    if currentPhase == .countdown {
                        countdownView
                    } else if currentPhase == .capturing {
                        capturingView
                    } else if currentPhase == .reviewing {
                        reviewingView
                    }
                }

                Spacer()

                instructionsView
                    .padding(.bottom, 30)
            }
        }
        .onAppear {
            controller.requestAndStart()
            if captureMode == .multiple {
                startMultipleCaptureSequence()
            } else {
                startCountdown()
            }
        }
        .onDisappear {
            controller.stop()
        }
        .onReceive(controller.bestImagePublisher) { best in
            if captureMode == .single {
                onCapturedBest(best)
            } else {
                capturedImages.append(best)
                if capturedImages.count < totalOutfitsToCapture {
                    // Continue to next outfit
                    currentOutfitNumber += 1
                    currentPhase = .reviewing
                } else {
                    // All outfits captured
                    onCapturedMultiple(capturedImages)
                }
            }
        }
    }

    private var countdownView: some View {
        VStack {
            Text("\(remaining)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if captureMode == .multiple {
                Text("Get ready for outfit \(currentOutfitNumber)")
                    .font(.headline)
                    .padding(.top, 8)
            }
        }
    }

    private var capturingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Capturing...")
                .font(.headline)
                .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var reviewingView: some View {
        VStack(spacing: 16) {
            if let lastImage = capturedImages.last {
                Image(uiImage: lastImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text("Great! Ready for the next outfit?")
                .font(.headline)
            
            HStack(spacing: 16) {
                Button("Retake") {
                    capturedImages.removeLast()
                    startCountdown()
                }
                .buttonStyle(.bordered)
                
                Button("Next Outfit") {
                    startCountdown()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var instructionsView: some View {
        Group {
            if currentPhase == .countdown {
                if captureMode == .multiple {
                    VStack(spacing: 8) {
                        Text("Hold still — I'll grab the best frame")
                            .font(.subheadline)
                        
                        Text("Pose naturally, show off your outfit \(currentOutfitNumber)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Text("Hold still — I'll grab the best frame")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private func startMultipleCaptureSequence() {
        currentOutfitNumber = 1
        capturedImages = []
        startCountdown()
    }

    private func startCountdown() {
        currentPhase = .countdown
        remaining = countdownSeconds
        Task {
            while remaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                remaining -= 1
            }
            currentPhase = .capturing
            controller.captureBurst(count: burstCount)
        }
    }
}

// MARK: - Camera Preview

private struct CameraPreview: UIViewControllerRepresentable {
    let controller: EnhancedCameraBurstController
    func makeUIViewController(context: Context) -> PreviewViewController {
        PreviewViewController(session: controller.session)
    }
    func updateUIViewController(_ uiViewController: PreviewViewController, context: Context) {
        uiViewController.updateSession(controller.session)
    }
}

final class PreviewViewController: UIViewController {
    private let previewLayer = AVCaptureVideoPreviewLayer()

    init(session: AVCaptureSession) {
        super.init(nibName: nil, bundle: nil)
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.layer.addSublayer(previewLayer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }

    func updateSession(_ session: AVCaptureSession) {
        previewLayer.session = session
    }
}

// MARK: - Enhanced Camera Controller

@MainActor
final class EnhancedCameraBurstController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    nonisolated let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var deviceInput: AVCaptureDeviceInput?

    /// Emits the best image after burst capture.
    let bestImagePublisher = PassthroughSubject<UIImage, Never>()
    
    /// Emits all captured images for multiple outfit analysis
    let allImagesPublisher = PassthroughSubject<[UIImage], Never>()

    private var captured: [UIImage] = []
    private var remainingBurst: Int = 0
    private var isCapturingMultiple = false

    deinit {
        if session.isRunning { session.stopRunning() }
    }

    func requestAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted { self?.configureAndStart() }
                }
            }
        default:
            break
        }
    }

    func stop() {
        if session.isRunning { session.stopRunning() }
        captured.removeAll()
    }

    private func configureAndStart() {
        guard !session.isRunning else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo

        if let input = deviceInput {
            session.removeInput(input)
        }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            session.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                deviceInput = input
            }
        } catch {
            session.commitConfiguration()
            return
        }

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()
        session.startRunning()
    }

    func captureBurst(count: Int) {
        captured.removeAll()
        remainingBurst = count
        captureNext()
    }

    private func captureNext() {
        guard remainingBurst > 0 else {
            publishBest()
            return
        }
        remainingBurst -= 1
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        output.capturePhoto(with: settings, delegate: self)
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            self.handlePhotoOutput(output, photo: photo, error: error)
        }
    }

    private func handlePhotoOutput(_ output: AVCapturePhotoOutput, photo: AVCapturePhoto, error: Error?) {
        if let error {
            print("Error capturing photo: \(error)")
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 250_000_000)
                self.captureNext()
            }
            return
        }

        if let data = photo.fileDataRepresentation(), let img = UIImage(data: data) {
            captured.append(img)
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            self.captureNext()
        }
    }

    private func publishBest() {
        guard !captured.isEmpty else { return }
        let best = captured.max { EnhancedImageScoring.overallQualityScore($0) < EnhancedImageScoring.overallQualityScore($1) } ?? captured[0]
        captured.removeAll()
        bestImagePublisher.send(best)
    }
}

// MARK: - Enhanced Image Scoring

enum EnhancedImageScoring {
    private static let context = CIContext(options: nil)
    
    /// Enhanced sharpness score using variance of Laplacian
    static func sharpnessScore(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0 }

        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CILaplacian")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        guard let output = filter?.outputImage else { return 0 }

        // Downsample for speed
        let extent = output.extent
        let width = max(1, Int(extent.width / 8.0))
        let height = max(1, Int(extent.height / 8.0))
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var buffer = [UInt8](repeating: 0, count: width * height)
        context.render(output,
                       toBitmap: &buffer,
                       rowBytes: width,
                       bounds: CGRect(x: 0, y: 0, width: width, height: height),
                       format: .R8,
                       colorSpace: colorSpace)

        let mean = buffer.map { Double($0) }.reduce(0, +) / Double(buffer.count)
        let variance = buffer.map { (Double($0) - mean) * (Double($0) - mean) }.reduce(0, +) / Double(buffer.count)
        return variance
    }
    
    /// Composition score based on rule of thirds and other photography principles
    static func compositionScore(_ image: UIImage) -> Double {
        // Simplified composition scoring
        // In a real implementation, this would analyze subject placement, lines, etc.
        return Double.random(in: 0.6...1.0)
    }
    
    /// Overall quality score combining multiple factors
    static func overallQualityScore(_ image: UIImage) -> Double {
        let sharpness = sharpnessScore(image)
        let composition = compositionScore(image)
        
        // Normalize sharpness score (assuming typical range 0-10000)
        let normalizedSharpness = min(sharpness / 10000.0, 1.0)
        
        return (normalizedSharpness * 0.7) + (composition * 0.3)
    }
}

#Preview {
    EnhancedCameraBurstView(
        captureMode: .multiple,
        countdownSeconds: 3,
        burstCount: 3,
        totalOutfitsToCapture: 3,
        onCancel: {},
        onCapturedBest: { _ in },
        onCapturedMultiple: { _ in }
    )
}