
import CoreImage
import AVFoundation

class CoreImageVideoFilter<Filter: CIFilter>: VideoFilterProtocol {
    private(set) var isPrepared = false
    private let buildFilter: () -> Filter
    private var ciContext: CIContext?
    private var ciFilter: Filter?
    private var outputColorSpace: CGColorSpace?
    private var outputPixelBufferPool: CVPixelBufferPool?
    private var inputFormatDescription: CMFormatDescription?
    private var outputFormatDescription: CMFormatDescription?

    internal init(_ filterBuilder: @escaping () -> Filter) {
        buildFilter = filterBuilder
    }

    @inlinable
    func prepare(inputFormatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) {
        reset()
        /// `let` is ommited due to direct assignment to properties.
        (outputPixelBufferPool, outputColorSpace, outputFormatDescription) = allocateOutputBufferPool(
            inputFormatDescription: inputFormatDescription,
            outputRetainedBufferCountHint: outputRetainedBufferCountHint
        )
        guard case .some = outputPixelBufferPool else {
            return
        }
        ciContext = CIContext(options: [
            .useSoftwareRenderer: false as NSNumber,
            .priorityRequestLow: false as NSNumber,
        ])
        ciFilter = buildFilter()
        isPrepared = true
    }

    @inlinable
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard isPrepared, let ciFilter, let ciContext else {
            assertionFailure("Invalid state: Not prepared")
            return .none
        }

        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        ciFilter.setValue(sourceImage, forKey: kCIInputImageKey)

        guard let outputImage = ciFilter.outputImage else {
            print("CIFilter failed to render image")
            return .none
        }

        var outputPixelBuffer: CVPixelBuffer?
        let error = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool!, &outputPixelBuffer)
        guard error == kCVReturnSuccess, let outputPixelBuffer else {
            print("Allocation failure")
            return .none
        }

        ciContext.render(outputImage, to: outputPixelBuffer, bounds: outputImage.extent, colorSpace: outputColorSpace)
        return outputPixelBuffer
    }

    @usableFromInline
    func reset() {
        ciContext = nil
        ciFilter = nil
        outputColorSpace = nil
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        isPrepared = false
    }
}

