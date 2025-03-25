
import SwiftUI
import CoreImage
import Combine
import AVFoundation
import Factory

final class CapturePreviewViewModel: ObservableObject {
    private var cancellable = Set<AnyCancellable>()

    @Injected(\.captureSessionManager) private var captureSessionManager
    @Injected(\.captureSession) private var captureSession
    @Injected(\.videoProcessor) private var videoProcessor

    private var pixelBufferRendering = Set<AnyCancellable>()
    private var displayLink = DisplayLink()
    private var pixelBuffer: CVPixelBuffer?

    @Published var image: CGImage?
    @Published var isFilterEnabled: Bool = false

    public var previewLayer: AVCaptureVideoPreviewLayer?

    private lazy var context: CIContext = {
        CIContext(options: [
            .useSoftwareRenderer: false as NSNumber,
            .priorityRequestLow: false as NSNumber,
        ])
    }()

    init() {
        setup()
    }

    private func setup() {
        observeFilterStatus()
    }
}

// MARK: - Public methods
extension CapturePreviewViewModel {
    func previewDidAppear() {
        captureSessionManager.startRunning()
    }

    func previewDidDisappear() {
        captureSessionManager.stopRunning()
        captureSessionManager.isPreviewEnabled = false
    }
}

// MARK: - Convenience accessors
extension CapturePreviewViewModel {
    var aspectRatio: CGFloat! {
        guard let formatDescription = captureSessionManager.videoInputDevice?.activeFormat.formatDescription else {
            return .none // should be unreachable, but not truly
        }
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        return CGFloat(dimensions.width) / CGFloat(dimensions.height)
    }
}

// MARK: Observing filter status
fileprivate extension CapturePreviewViewModel {
    func observeFilterStatus() {
        videoProcessor.isFilterEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.toggleFilter($0)
            }
            .store(in: &cancellable)
    }

    func toggleFilter(_ isEnabled: Bool) {
        if isEnabled {
            setupFilteredImageOutputIfNeeded()
            previewLayer = .none
        } else {
            dismantleFilteredImageOutput()
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        }
        withAnimation(.snappy) {
            isFilterEnabled = isEnabled
        }
    }
}

// MARK: Filtered image preview
fileprivate extension CapturePreviewViewModel {
    func setupFilteredImageOutputIfNeeded() {
        guard pixelBufferRendering.isEmpty else { return }
        displayLink.frameSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.renderImageIfNeeded()
            }
            .store(in: &pixelBufferRendering)
        videoProcessor.latestFrame
            .receive(on: videoProcessor.queue)
            .sink { [weak self] in
                self?.pixelBuffer = $0
            }
            .store(in: &pixelBufferRendering)
        displayLink.activate()
    }

    func renderImageIfNeeded() {
        guard let pixelBuffer else { return }
        let coreImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let image = context.createCGImage(coreImage, from: coreImage.extent) else { return }
        self.image = image
    }

    func dismantleFilteredImageOutput() {
        pixelBufferRendering.removeAll()
        pixelBuffer = .none
        image = .none
        displayLink = DisplayLink()
    }
}
