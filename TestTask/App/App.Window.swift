
extension App {
    enum Window: String, Identifiable {
        case conferenceSettings = "Conference Settings"
        case cameraPreview = "Camera Preview"
        case knownDevices = "Devices"

        var id: String { rawValue }
    }
}
