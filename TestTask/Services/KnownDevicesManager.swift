
import Combine
import AVFoundation
import Factory

final class KnownDevicesManager: ObservableObject {
    private var cancellable = Set<AnyCancellable>()
    private var configuration: Configuration = .standard

    @Injected(\.userNotificationService) private var userNotificationService
    @Injected(\.captureDeviceObserver) private var captureDeviceObserver
    @Injected(\.playbackDeviceObserver) private var playbackDeviceObserver

    @Published public private(set) var devices: [KnownDevice] = []
    @Published public var trackedDevicesIds = Set<KnownDevice.TrackingID>() {
        didSet {
            persistConfiguration()
        }
    }
    @Published public var notificationSettings: KnownDevice.NotificationSettings = .init() {
        didSet {
            persistConfiguration()
        }
    }
    /// `KnownDevice`'s `Hashable & Equatable` conformances ignore `isConnected` property, thus view update is forced.
    @Published public private(set) var refreshToken: String = UUID().uuidString

    private let sortOrder = [
        KeyPathComparator(\KnownDevice.mediaType),
        KeyPathComparator(\KnownDevice.bufferType),
        KeyPathComparator(\KnownDevice.name),
    ]

    init() {
        setup()
    }

    private func setup() {
        restoreConfiguration()
        gatherCurrentDevices()
        applySort()
        observeDeviceChanges()
    }
}

// MARK: - Intitial devices configuration
fileprivate extension KnownDevicesManager {
    func gatherCurrentDevices() {
        let input = Set(captureDeviceObserver.devices.map { KnownDevice(device: $0) })
        let output = Set(playbackDeviceObserver.devices.map { KnownDevice(device: $0, isConnected: true) })
        let currentDevices = input.union(output)
        /// `KnownDevices` should be stored, but just making a union won't change the `isConnected` property since it's
        /// not being hashed or used for equating
        for device in currentDevices {
            if let index = devices.firstIndex(of: device) {
                devices.remove(at: index)
                devices.insert(device, at: index)
            } else {
                devices.append(device)
            }
        }
    }
}

// MARK: - Convenience
fileprivate extension KnownDevicesManager {
    func applySort() {
        devices.sort(using: sortOrder)
    }

    func setRefreshNeeded() {
        refreshToken = UUID().uuidString
    }
}

// MARK: - Convenience Accessors
import SwiftUI

extension KnownDevicesManager {
    func tracking(_ device: KnownDevice) -> Binding<Bool> {
        .init { [unowned self] in
            trackedDevicesIds.contains(device.trackingId)
        } set: { [unowned self] shouldTrack in
            if shouldTrack {
                trackedDevicesIds.insert(device.trackingId)
            } else {
                trackedDevicesIds.remove(device.trackingId)
            }
        }
    }
}

// MARK: - Dispatching notifications
fileprivate extension KnownDevicesManager {
    func notifyDeviceStatusChangeIfNeeded(
        device: KnownDevice,
        isNew: Bool
    ) {
        Task { [weak userNotificationService] in
            guard let userNotificationService else { return }
            if isNew && notificationSettings.shouldTrackNewDeviceConnections {
                userNotificationService.submit(.init(device: device, isNew: isNew))
            } else if !isNew {
                if notificationSettings.shouldTrackDeviceConnectins && device.isConnected {
                    guard trackedDevicesIds.contains(device.trackingId) else { return }
                    userNotificationService.submit(.init(device: device, isNew: isNew))
                } else if notificationSettings.shouldTrackDeviceDisconnections && !device.isConnected {
                    guard trackedDevicesIds.contains(device.trackingId) else { return }
                    userNotificationService.submit(.init(device: device, isNew: isNew))
                }
            }
        }
    }
}

// MARK: - Observing device changes
fileprivate extension KnownDevicesManager {
    func handleDeviceConnectionUpdate(device: KnownDevice) {
        let isNew: Bool
        if let index = devices.firstIndex(of: device) {
            isNew = false
            devices.remove(at: index)
            devices.insert(device, at: index)
        } else {
            /// connected and not known = new
            isNew = true
            devices.append(device)
            applySort()
            persistConfiguration()
        }
        notifyDeviceStatusChangeIfNeeded(device: device, isNew: isNew)
        setRefreshNeeded()
    }

    func observeDeviceChanges() {
        Publishers.MergeMany([
            captureDeviceObserver.deviceDidConnect
                .map { KnownDevice(device: $0) }
                .eraseToAnyPublisher(),
            playbackDeviceObserver.deviceDidConnect
                .map { KnownDevice(device: $0, isConnected: true) }
                .eraseToAnyPublisher(),
            captureDeviceObserver.deviceDidDisconnect
                .map { KnownDevice(device: $0) }
                .eraseToAnyPublisher(),
            playbackDeviceObserver.deviceDidDisconnect
                .map { KnownDevice(device: $0, isConnected: false) }
                .eraseToAnyPublisher(),
        ])
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in
            self?.handleDeviceConnectionUpdate(device: $0)
        }
        .store(in: &cancellable)
    }
}

// MARK: - Configuration
extension KnownDevicesManager {
    /// Holds `KnownDevice.NotificationSettings`, `[KnownDevices]`, `[KnownDevice.TrackingID]`, allows persisting
    /// changes in between sessions.
    private struct Configuration: Codable, Restorable, Persistable {
        var notificationSettings: KnownDevice.NotificationSettings
        var knownDevices: [KnownDevice]
        var trackedDevicesIds: [KnownDevice.TrackingID]

        static let persistanceKey: String = "KnownDevicesManager-Configuration"

        static var standard: Self {
            .init(notificationSettings: .init(), knownDevices: [], trackedDevicesIds: [])
        }
    }

    func restoreConfiguration() {
        do {
            configuration = try .restore()
        } catch {
            #if DEBUG
            print(error.localizedDescription)
            #endif
        }
        notificationSettings = configuration.notificationSettings
        /// load them as disconnected, those which are connected will be overriden in `gatherCurrentDevices`
        devices = configuration.knownDevices.map { $0.asDisconnected() }
        trackedDevicesIds = Set(configuration.trackedDevicesIds)
    }

    func persistConfiguration() {
        do {
            try Configuration(
                notificationSettings: notificationSettings,
                knownDevices: devices,
                trackedDevicesIds: Array(trackedDevicesIds)
            ).persist()
        } catch {
            #if DEBUG
            print(error.localizedDescription)
            #endif
        }
    }
}
