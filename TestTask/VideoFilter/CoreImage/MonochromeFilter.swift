
import CoreImage.CIFilterBuiltins

final class MonochromeFilter: CoreImageVideoFilter<CIFilter & CIPhotoEffect> {
    init() {
        super.init { CIFilter.photoEffectMono() }
    }
}
