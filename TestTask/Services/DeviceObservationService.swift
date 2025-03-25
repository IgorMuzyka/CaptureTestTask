
import SwiftUI
import Combine
import AVFoundation
import Factory

final class DeviceObservationService: ObservableObject {
    @Injected(\.playbackDeviceObserver) private var playbackDeviceObserver
    @Injected(\.captureDeviceObserver) private var captureDeviceObserver
}

// MARK: - Accessors
extension DeviceObservationService {
    public var defaultVideoInputDevice: AVCaptureDevice? {
        captureDeviceObserver.defaultVideoDevice
    }

    public var defaultAudioInputDevice: AVCaptureDevice? {
        captureDeviceObserver.defaultAudioDevice
    }

    public var defaultAudioOutputDevice: PlaybackDevice? {
        playbackDeviceObserver.defaultOutputDevice
    }

    public var videoInputDevices: [AVCaptureDevice] {
        captureDeviceObserver.devices.filter { $0.hasMediaType(.video) }
    }

    public var audioInputDevices: [AVCaptureDevice] {
        captureDeviceObserver.devices.filter { $0.hasMediaType(.audio) }
    }

    public var audioOutputDevices: [PlaybackDevice] {
        playbackDeviceObserver.devices
    }

    public var captureDeviceDidDisconnect: PassthroughSubject<AVCaptureDevice, Never> {
        captureDeviceObserver.deviceDidDisconnect
    }

    public var playbackDeviceDidDisconnect: PassthroughSubject<PlaybackDevice, Never> {
        playbackDeviceObserver.deviceDidDisconnect
    }
}
