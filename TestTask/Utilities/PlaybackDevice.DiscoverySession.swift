
import CoreAudio

public extension PlaybackDevice {
    /// A parody on `AVCaptureDevice.DiscoverySession`.
    final class DiscoverySession {
        private typealias AudioDeviceChangedCallback =
            @convention(c)
            (AudioObjectID, UInt32, UnsafePointer<AudioObjectPropertyAddress>, UnsafeMutableRawPointer?) -> OSStatus
        private let callback: AudioDeviceChangedCallback

        public init() throws(Error) {
            self.callback = { _, _, _, _ in
                NotificationCenter.default.post(.init(name: PlaybackDevice.devicesDidChangeNotification))
                return noErr
            }
            try startObserving()
        }

        deinit {
            try! stopObserving()
        }
    }
}

// MARK: - Devices & Default Device accesors
public extension PlaybackDevice.DiscoverySession {
    var devices: [PlaybackDevice] {
        get throws(Error) {
            let deviceIds = try deviceIds
            var devices: [PlaybackDevice] = []

            for deviceId in deviceIds {
                do throws(Error) {
                    guard case true = try isOutputDevice(deviceId) else {
                        throw .deviceIsNotForOutput
                    }
                    let name = try getDeviceName(deviceId)
                    let uniqueId = try getDeviceUniqueId(deviceId)
                    devices.append(.init(deviceId: deviceId, uniqueID: uniqueId, name: name))
                } catch {
                    continue
                }
            }

            return devices
        }
    }

    var defaultDevice: PlaybackDevice? {
        get throws(Error) {
            guard let deviceId = try defaultOutputDeviceId else {
                throw .failedToGetDefaultDevice
            }
            let name = try getDeviceName(deviceId)
            let uniqueId = try getDeviceUniqueId(deviceId)
            return PlaybackDevice(deviceId: deviceId, uniqueID: uniqueId, name: name)
        }
    }
}

// MARK: - Device changes observation
fileprivate extension PlaybackDevice.DiscoverySession {
    func startObserving() throws(Error) {
        var address = devicesAddress
        let status = AudioObjectAddPropertyListener(
            objectId,
            &address,
            callback,
            .none
        )
        guard status == noErr else {
            throw .failedToStartObservingDeviceChanges
        }
    }

    func stopObserving() throws(Error) {
        var address = devicesAddress
        let status = AudioObjectRemovePropertyListener(
            objectId,
            &address,
            callback,
            .none
        )
        guard status == noErr else {
            throw .failedToStopObservingDeviceChanges
        }
    }
}

// MARK: - Device IDs
fileprivate extension PlaybackDevice.DiscoverySession {
    var defaultOutputDeviceId: AudioDeviceID? {
        get throws(Error) {
            var defaultDeviceId: AudioDeviceID = kAudioDeviceUnknown
            var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
            var address = defaultOutputDeviceAddress
            let status = AudioObjectGetPropertyData(objectId, &address, 0, .none, &propertySize, &defaultDeviceId)
            guard status == noErr else {
                throw .failedToGetDefaultDevice
            }
            guard defaultDeviceId != kAudioDeviceUnknown else { return .none }
            return defaultDeviceId
        }
    }

    var deviceIds: [AudioDeviceID] {
        get throws(Error) {
            var deviceIds: [AudioDeviceID] = []
            var propertySize = UInt32(0)
            var address = devicesAddress
            var status = AudioObjectGetPropertyDataSize(objectId, &address, 0, .none, &propertySize)
            guard status == noErr else {
                throw .failedToGetObjectPropertyDataSize
            }

            let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
            deviceIds = Array(repeating: 0, count: deviceCount)

            status = AudioObjectGetPropertyData(objectId, &address, 0, .none, &propertySize, &deviceIds)
            guard status == noErr else {
                throw .failedToGetObjectPropertyData
            }

            return deviceIds
        }
    }
}


// MARK: - Getting Device Properties
fileprivate extension PlaybackDevice.DiscoverySession {
    func getDeviceName(_ deviceId: AudioDeviceID) throws(Error) -> String {
        var namePointer: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<CFString>.size)
        var address = nameAddress
        let status = AudioObjectGetPropertyData(deviceId, &address, 0, .none, &size, &namePointer)
        guard status == noErr else {
            throw .failedToGetObjectPropertyData
        }
        guard let name = namePointer?.takeUnretainedValue() as String? else {
            throw .failedToGetDeviceName
        }
        return name
    }

    func getDeviceUniqueId(_ deviceId: AudioObjectID) throws(Error) -> String {
        var uniqueIdPointer: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<CFString>.size)
        var address = uniqueIdAddress
        let status = AudioObjectGetPropertyData(deviceId, &address, 0, .none, &size, &uniqueIdPointer)
        guard status == noErr else {
            throw .failedToGetObjectPropertyData
        }
        guard let uniqueId = uniqueIdPointer?.takeUnretainedValue() as String? else {
            throw .failedToGetDeviceUniqueId
        }
        return uniqueId
    }

    func isOutputDevice(_ deviceId: AudioDeviceID) throws(Error) -> Bool {
        var outputAddress = outputAddress
        var status = noErr
        var streamConfigSize = UInt32(0)
        status = AudioObjectGetPropertyDataSize(deviceId, &outputAddress, 0, .none, &streamConfigSize)
        guard status == noErr else {
            throw .failedToGetObjectPropertyDataSize
        }
        var streamConfig: AudioBufferList = AudioBufferList()
        status = AudioObjectGetPropertyData(deviceId, &outputAddress, 0, .none, &streamConfigSize, &streamConfig)
        guard status == noErr else {
            throw .failedToGetObjectPropertyData
        }
        return streamConfig.mNumberBuffers > 0
    }
}

// MARK: - Convenience
fileprivate extension PlaybackDevice.DiscoverySession {
    var objectId: AudioObjectID { AudioObjectID(kAudioObjectSystemObject) }

    var outputAddress: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    var nameAddress: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    var uniqueIdAddress: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    var defaultOutputDeviceAddress: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    var devicesAddress: AudioObjectPropertyAddress {
            AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    }
}

// MARK: - Error
public extension PlaybackDevice.DiscoverySession {
    enum Error: Swift.Error, LocalizedError {
        // interacting with core audio
        case failedToGetObjectPropertyDataSize
        case failedToGetObjectPropertyData
        // change listener
        case failedToStartObservingDeviceChanges
        case failedToStopObservingDeviceChanges
        // logical
        case deviceIsNotForOutput
        case failedToGetDefaultDevice
        case failedToGetDeviceName
        case failedToGetDeviceUniqueId

        public var errorDescription: String? {
            switch self {
                case .failedToGetObjectPropertyDataSize: "failed to get object proeprty data size"
                case .failedToGetObjectPropertyData: "failed to get object property data"
                case .failedToStartObservingDeviceChanges: "failed to start observing device changes"
                case .failedToStopObservingDeviceChanges: "failed to stop observing device changes"
                case .deviceIsNotForOutput: "device is not for output"
                case .failedToGetDefaultDevice: "failed to get default device"
                case .failedToGetDeviceName: "failed to get device name"
                case .failedToGetDeviceUniqueId: "failed to get device unique id"
            }
        }
    }
}
