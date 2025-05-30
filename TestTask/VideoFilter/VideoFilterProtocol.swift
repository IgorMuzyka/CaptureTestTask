
import CoreMedia

protocol VideoFilterProtocol: AnyObject {
    var isPrepared: Bool { get }

    @inlinable func prepare(inputFormatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int)

    @inlinable func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
}

// MARK: - CVPixelBufferPool pre/allocation helper
/// borrowed from [here](https://developer.apple.com/documentation/avfoundation/avcamfilter-applying-filters-to-a-capture-stream)
extension VideoFilterProtocol {
    typealias AllocateOutputBufferPoolOutput = (
        outputBufferPool: CVPixelBufferPool?,
        outputColorSpace: CGColorSpace?,
        outputFormatDescription: CMFormatDescription?
    )

    @usableFromInline
    func allocateOutputBufferPool(
        inputFormatDescription: CMFormatDescription,
        outputRetainedBufferCountHint: Int
    ) -> AllocateOutputBufferPoolOutput {
        let inputMediaSubType = CMFormatDescriptionGetMediaSubType(inputFormatDescription)
        if inputMediaSubType != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
            assertionFailure("Invalid input pixel buffer type \(inputMediaSubType)")
            return (.none, .none, .none)
        }

        let inputDimensions = inputFormatDescription.dimensions
        var pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: UInt(inputMediaSubType),
            kCVPixelBufferWidthKey as String: Int(inputDimensions.width),
            kCVPixelBufferHeightKey as String: Int(inputDimensions.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]

        // Get pixel buffer attributes and color space from the input format description.
        var cgColorSpace = CGColorSpaceCreateDeviceRGB()
        if let inputFormatDescriptionExtension = CMFormatDescriptionGetExtensions(inputFormatDescription) as Dictionary? {
            let colorPrimaries = inputFormatDescriptionExtension[kCVImageBufferColorPrimariesKey]

            if let colorPrimaries = colorPrimaries {
                var colorSpaceProperties: [String: AnyObject] = [kCVImageBufferColorPrimariesKey as String: colorPrimaries]

                if let yCbCrMatrix = inputFormatDescriptionExtension[kCVImageBufferYCbCrMatrixKey] {
                    colorSpaceProperties[kCVImageBufferYCbCrMatrixKey as String] = yCbCrMatrix
                }

                if let transferFunction = inputFormatDescriptionExtension[kCVImageBufferTransferFunctionKey] {
                    colorSpaceProperties[kCVImageBufferTransferFunctionKey as String] = transferFunction
                }

                pixelBufferAttributes[kCVBufferPropagatedAttachmentsKey as String] = colorSpaceProperties
            }

            if let cvColorspace = inputFormatDescriptionExtension[kCVImageBufferCGColorSpaceKey] {
                cgColorSpace = cvColorspace as! CGColorSpace
            } else if (colorPrimaries as? String) == (kCVImageBufferColorPrimaries_P3_D65 as String) {
                cgColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
            }
        }

        // Create a pixel buffer pool with the same pixel attributes as the input format description.
        let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: outputRetainedBufferCountHint]
        var cvPixelBufferPool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as NSDictionary?, pixelBufferAttributes as NSDictionary?, &cvPixelBufferPool)
        guard let pixelBufferPool = cvPixelBufferPool else {
            assertionFailure("Allocation failure: Could not allocate pixel buffer pool.")
            return (.none, .none, .none)
        }

        preallocateBuffers(pool: pixelBufferPool, allocationThreshold: outputRetainedBufferCountHint)

        // Get the output format description.
        var pixelBuffer: CVPixelBuffer?
        var outputFormatDescription: CMFormatDescription?
        let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: outputRetainedBufferCountHint] as NSDictionary
        CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pixelBufferPool, auxAttributes, &pixelBuffer)
        if let pixelBuffer = pixelBuffer {
            CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescriptionOut: &outputFormatDescription
            )
        }
        pixelBuffer = .none

        return (pixelBufferPool, cgColorSpace, outputFormatDescription)
    }

    @usableFromInline
    func preallocateBuffers(pool: CVPixelBufferPool, allocationThreshold: Int) {
        var pixelBuffers = [CVPixelBuffer]()
        var error: CVReturn = kCVReturnSuccess
        let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: allocationThreshold] as NSDictionary
        var pixelBuffer: CVPixelBuffer?
        while error == kCVReturnSuccess {
            error = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer)
            if let pixelBuffer = pixelBuffer {
                pixelBuffers.append(pixelBuffer)
            }
            pixelBuffer = .none
        }
        pixelBuffers.removeAll()
    }
}
