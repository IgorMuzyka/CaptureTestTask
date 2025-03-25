
import Combine
import AVFoundation

final class VideoProcessor: NSObject {
    public let queue = DispatchQueue(
        label: "VideoProcessingQueue",
        qos: .userInitiated,
        autoreleaseFrequency: .workItem
    )
    public let videoDataOutput = AVCaptureVideoDataOutput()
    public let latestFrame = PassthroughSubject<CVPixelBuffer, Never>()
    public let isFilterEnabled = CurrentValueSubject<Bool, Never>(false)
    private var videoFilter: VideoFilterProtocol? = .none {
        didSet {
            if case .none = videoFilter {
                isFilterEnabled.send(false)
            } else {
                isFilterEnabled.send(true)
            }
        }
    }
    private var filtersByKind: [VideoFilter: VideoFilterProtocol] = [
        .monochrome: MonochromeFilter(),
        .sepia: SepiaFilter(),
        .thermal: ThermalFilter(),
        .xRay: XRayFilter(),
        .mosaic: MosaicFilter(),
        .comic: ComicFilter(),
        .edges: EdgesFilter(),
    ]

    override init() {
        super.init()
        setup()
    }

    public func assing(_ filterKind: VideoFilter) {
        queue.async { [weak self] in
            guard let self else { return }
            self.videoFilter = self.filtersByKind[filterKind]
        }
    }

    private func setup() {
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        ]
        videoDataOutput.setSampleBufferDelegate(self, queue: queue)
    }
}

// MARK: - Processing CMSampleBuffer
extension VideoProcessor {
    @inlinable
    func process(_ sampleBuffer: CMSampleBuffer) {
        guard
            let videoPixelBuffer = sampleBuffer.imageBuffer,
            let formatDescription = sampleBuffer.formatDescription
        else {
            return
        }
        var outputPixelBuffer = videoPixelBuffer
        defer {
            latestFrame.send(outputPixelBuffer)
        }
        // no filter, filter no processing
        guard let videoFilter else { return }
        if !videoFilter.isPrepared {
            videoFilter.prepare(
                inputFormatDescription: formatDescription,
                outputRetainedBufferCountHint: 3
            )
        }
        guard let filteredPixelBuffer = videoFilter.render(pixelBuffer: outputPixelBuffer) else {
            return
        }
        outputPixelBuffer = filteredPixelBuffer
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension VideoProcessor: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard isFilterEnabled.value else { return }
        process(sampleBuffer)
    }
}
