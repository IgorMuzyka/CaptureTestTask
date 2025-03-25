
import CoreImage.CIFilterBuiltins

final class ComicFilter: CoreImageVideoFilter<CIFilter & CIComicEffect> {
    init() {
        super.init { CIFilter.comicEffect() }
    }
}
