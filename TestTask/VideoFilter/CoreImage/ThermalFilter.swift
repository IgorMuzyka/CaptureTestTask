
import CoreImage.CIFilterBuiltins

final class ThermalFilter: CoreImageVideoFilter<CIFilter & CIThermal> {
    init() {
        super.init { CIFilter.thermal() }
    }
}
