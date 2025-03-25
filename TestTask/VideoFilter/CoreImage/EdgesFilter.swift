
import CoreImage.CIFilterBuiltins

final class EdgesFilter: CoreImageVideoFilter<CIFilter & CICannyEdgeDetector> {
    init() {
        super.init {
            let filter = CIFilter.cannyEdgeDetector()
            filter.gaussianSigma = 5
            filter.perceptual = false
            filter.thresholdLow = 0.02
            filter.thresholdHigh = 0.05
            filter.hysteresisPasses = 1
            return filter
        }
    }
}
