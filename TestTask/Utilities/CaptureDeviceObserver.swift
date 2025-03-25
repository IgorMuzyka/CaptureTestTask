
import AVFoundation
import Combine

/// Observes audio & video capture devices.
public final class CaptureDeviceObserver {
    private var cancellable: Set<AnyCancellable> = []
    private let discoverySession: AVCaptureDevice.DiscoverySession

    public private(set) var devices: [AVCaptureDevice] = []
    public let deviceDidConnect = PassthroughSubject<AVCaptureDevice, Never>()
    public let deviceDidDisconnect = PassthroughSubject<AVCaptureDevice, Never>()

    public init(
        deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .microphone,
            .external,
//            .continuityCamera,
//            .deskViewCamera,
        ]
    ) {
        discoverySession = .init(deviceTypes: deviceTypes, mediaType: .none, position: .unspecified)
        setup()
    }

    private func setup() {
        observeDeviceChanges()
        update()
    }
}

// MARK: - Convenience accessors
public extension CaptureDeviceObserver {
    var defaultAudioDevice: AVCaptureDevice? {
        .default(for: .audio)
    }

    var defaultVideoDevice: AVCaptureDevice? {
        .default(for: .video)
    }
}

// MARK: - Observing device connection notifications
fileprivate extension CaptureDeviceObserver {
    func observeDeviceChanges() {
        NotificationCenter.default
            .publisher(for: AVCaptureDevice.wasConnectedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.update()
                self?.deviceStatusChanged(device: notification.object as? AVCaptureDevice, connected: true)
            }
            .store(in: &cancellable)
        NotificationCenter.default
            .publisher(for: AVCaptureDevice.wasDisconnectedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.update()
                self?.deviceStatusChanged(device: notification.object as? AVCaptureDevice, connected: false)
            }
            .store(in: &cancellable)
    }

    private func update() {
        devices = discoverySession.devices
    }

    func deviceStatusChanged(device: AVCaptureDevice?, connected: Bool) {
        guard let device else { return }
        let subject = connected ? deviceDidConnect : deviceDidDisconnect
        subject.send(device)
    }
}
