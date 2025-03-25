
import CoreImage.CIFilterBuiltins

final class XRayFilter: CoreImageVideoFilter<CIFilter & CIXRay> {
    init() {
        super.init { CIFilter.xRay() }
    }
}
