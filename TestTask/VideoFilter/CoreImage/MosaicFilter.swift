
import CoreImage.CIFilterBuiltins

final class MosaicFilter: CoreImageVideoFilter<CIFilter & CICrystallize> {
    init(radius: Float = 16) {
        super.init {
            let filter = CIFilter.crystallize()
            filter.radius = radius
            return filter
        }
    }
}

