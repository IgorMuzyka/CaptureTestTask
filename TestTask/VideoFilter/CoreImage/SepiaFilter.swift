
import CoreImage.CIFilterBuiltins

final class SepiaFilter: CoreImageVideoFilter<CIFilter & CISepiaTone> {
    init(intensity: Float = 1) {
        super.init {
            let filter = CIFilter.sepiaTone()
            filter.intensity = 1
            return filter
        }
    }
}
