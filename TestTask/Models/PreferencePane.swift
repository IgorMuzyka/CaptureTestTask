
import Foundation

/// Used to open system preference, here's a [reference](https://gist.github.com/rmcdongit/f66ff91e0dad78d4d6346a75ded4b751).
enum PreferencePane {
    static let cameraSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")!
    static let microphoneSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
}
