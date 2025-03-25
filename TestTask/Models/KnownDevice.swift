
/// A shallow device descriptor
struct KnownDevice: Identifiable, Codable {
    var id: String { "\(hashValue)"}

    let uniqueID: String
    let name: String
    enum BufferType: Int, Codable {
        case capture = 0
        case playback = 1
    }
    let bufferType: BufferType
    enum MediaType: Int, Codable {
        case muxed = 0
        case video = 1
        case audio = 2
        case other = 3
    }
    let mediaType: MediaType
    var isConnected: Bool

    typealias TrackingID = String

    /// device `uniqueId` might change between app launches, so here's a simple alternative.
    var trackingId: TrackingID {
        "\(name)\(mediaType)\(bufferType)"
    }

    init(
        uniqueId: String,
        name: String,
        bufferType: BufferType,
        mediaType: MediaType,
        isConnected: Bool
    ) {
        self.uniqueID = uniqueId
        self.name = name
        self.bufferType = bufferType
        self.mediaType = mediaType
        self.isConnected = isConnected
    }
}

// MARK: Hashable, Equatable, CustomStringConvertible
extension KnownDevice: Hashable, Equatable, CustomStringConvertible {
    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueID)
        hasher.combine(name)
        hasher.combine(mediaType)
        hasher.combine(bufferType)
    }

    static func ==(lhs: KnownDevice, rhs: KnownDevice) -> Bool {
        lhs.hashValue == rhs.hashValue
    }


    var description: String {
        let descriptions = [
            name,
            bufferType.description,
            mediaType.description,
            (isConnected ? "🟢" : "🔴"),
        ].joined(separator: ",")
        return "Device(" + descriptions + ")"
    }
}

// MARK: - Convenience initialiers
import AVFoundation

extension KnownDevice {
    init(device: AVCaptureDevice) {
        var mediaType: MediaType = .other
        let hasVideoMediaType = device.hasMediaType(.video)
        let hasAudioMediaType = device.hasMediaType(.audio)

        if hasAudioMediaType && hasVideoMediaType {
            mediaType = .muxed
        } else if hasAudioMediaType {
            mediaType = .audio
        } else if hasVideoMediaType {
            mediaType = .video
        } else {
            mediaType = .other
        }

        self.init(
            uniqueId: device.uniqueID,
            name: device.localizedName,
            bufferType: .capture,
            mediaType: mediaType,
            isConnected: device.isConnected
        )
    }
}

extension KnownDevice {
    init(device: PlaybackDevice, isConnected: Bool) {
        self.init(
            uniqueId: device.uniqueID,
            name: device.name,
            bufferType: .playback,
            mediaType: .audio,
            isConnected: isConnected
        )
    }
}

// MARK: - Convenience
extension KnownDevice {
    func asDisconnected() -> Self {
        var new = self
        new.isConnected = false
        return new
    }
}

extension KnownDevice.BufferType: CustomStringConvertible, Comparable {
    var description: String {
        switch self {
            case .capture: "Input"
            case .playback: "Output"
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension KnownDevice.MediaType: CustomStringConvertible, Comparable {
    var description: String {
        switch self {
            case .audio: "Audio"
            case .video: "Video"
            case .muxed: "Audio/Video"
            case .other: "Other"
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
