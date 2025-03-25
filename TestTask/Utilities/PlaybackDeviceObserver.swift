
import Foundation
import Combine

/// Observes audio output devices.
public final class PlaybackDeviceObserver {
    private var cancellable: Set<AnyCancellable> = []
    private let discoverySession: PlaybackDevice.DiscoverySession

    public private(set) var devices: [PlaybackDevice] = []
    public let deviceDidConnect = PassthroughSubject<PlaybackDevice, Never>()
    public let deviceDidDisconnect = PassthroughSubject<PlaybackDevice, Never>()

    init() {
        discoverySession = try! .init()
        setup()
    }

    private func setup() {
        observeDeviceChanges()
        update()
    }
}

// MARK: - Convenience accessors
public extension PlaybackDeviceObserver {
    var defaultOutputDevice: PlaybackDevice? {
        try? discoverySession.defaultDevice
    }
}

// MARK: - Observing device changes
fileprivate extension PlaybackDeviceObserver {
    private func observeDeviceChanges() {
        NotificationCenter.default
            .publisher(for: PlaybackDevice.devicesDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.update()
            }
            .store(in: &cancellable)
    }

    private func update() {
        let currentDevices = (try? discoverySession.devices) ?? []
        dispatchChanges(currentDevices.difference(from: devices))
        devices = currentDevices
    }

    private func dispatchChanges(_ difference: CollectionDifference<PlaybackDevice>) {
        difference
            .compactMap {
                guard case let .insert(_, device, associatedWith: .none) = $0 else { return .none }
                return device
            }
            .forEach(deviceDidConnect.send)
        difference
            .compactMap {
                guard case let .remove(_, device, associatedWith: .none) = $0 else { return .none }
                return device
            }
            .forEach(deviceDidDisconnect.send)
    }
}
