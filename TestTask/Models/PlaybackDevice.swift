
import CoreAudio

public struct PlaybackDevice: Identifiable, Hashable, Equatable {
    public var id: String { uniqueID }
    public let deviceId: AudioDeviceID
    public let uniqueID: String
    public let name: String

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.uniqueID == rhs.uniqueID
    }
}

// MARK: - Devices Did Change Notification.Name
public extension PlaybackDevice {
    static var devicesDidChangeNotification: Notification.Name {
        .init(rawValue: "PlaybackDevice.devicesDidChange")
    }
}
