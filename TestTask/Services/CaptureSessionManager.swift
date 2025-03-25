
import SwiftUI
import Combine
import AVFoundation
import Factory

final class CaptureSessionManager: ObservableObject {
    private var cancellable = Set<AnyCancellable>()
    private let captureSessionConfigurationThrottle: CombineTime = .milliseconds(50)
    private let sessionQueue = DispatchQueue(
        label: "CaptureSessionQueue",
        qos: .userInteractive,
        autoreleaseFrequency: .workItem
    )

    @Injected(\.deviceAuthorizationHelper) private var deviceAuthorizationHelper
    @Injected(\.deviceObservationService) private var deviceObservationService
    @Injected(\.videoProcessor) private var videoProcessor
    @Injected(\.captureSession) private var captureSession

    @Published public var videoInputDevice: AVCaptureDevice?
    @Published public var audioInputDevice: AVCaptureDevice?
    /// not used in any way, but nice to show that option in the UI nonetheless
    @Published public var audioOutputDevice: PlaybackDevice?
    @Published public var videoFilter: VideoFilter = .unspecified {
        didSet {
            videoProcessor.assing(videoFilter)
        }
    }
    @Published public var isPreviewEnabled: Bool = false

    public init() {
        setup()
    }

    deinit {
        stopRunning()
    }
}

// MARK: - Setup & Configuration
fileprivate extension CaptureSessionManager {
    func setup() {
        revertToDefaultDevicesIfNeeded()
        observeDeviceChangesAndReconfigureCaptureSession()
        observeDisconnectionsAndFallbackIfNeeded()
    }

    /// when device is unset and theres a default one set it.
    func revertToDefaultDevicesIfNeeded() {
        if case .none = videoInputDevice, let fallback = deviceObservationService.defaultVideoInputDevice {
            videoInputDevice = fallback
        }
        if case .none = audioInputDevice, let fallback = deviceObservationService.defaultAudioInputDevice {
            audioInputDevice = fallback
        }
        if case .none = audioOutputDevice, let fallback = deviceObservationService.defaultAudioOutputDevice {
            audioOutputDevice = fallback
        }
    }

    func reconfigureCaptureSession() {
        let isVideoAuthorized: Bool = deviceAuthorizationHelper.videoAuthorizationStatus == .authorized
        let isAudioAuthorized: Bool = deviceAuthorizationHelper.audioAuthorizationStatus == .authorized
        let videoDataOutput = videoProcessor.videoDataOutput
        sessionQueue.async { [weak captureSession, weak videoInputDevice, weak audioInputDevice] in
            guard let captureSession else { return }
            let configurator = CaptureSessionConfigurator(captureSession: captureSession)
            let errors = configurator.reconfigure(
                videoInputDevice: isVideoAuthorized ? videoInputDevice : .none,
                audioInputDevice: isAudioAuthorized ? audioInputDevice : .none,
                videouDataOutput: isVideoAuthorized ? videoDataOutput : .none
            )
            #if DEBUG
            guard let errors else { return }
            errors.forEach {
                print($0.localizedDescription)
            }
            #else
            _ = errors
            #endif
        }
    }
}

// MARK: - Public methods
extension CaptureSessionManager {
    func startRunning() {
        guard !captureSession.isRunning else { return }
        sessionQueue.async { [weak captureSession] in
            captureSession?.startRunning()
        }
    }

    func stopRunning() {
        guard captureSession.isRunning else { return }
        sessionQueue.async { [weak captureSession] in
            captureSession?.stopRunning()
        }
    }
}

// MARK: - Convenience
private extension CaptureSessionManager {
    typealias CombineTime = DispatchQueue.SchedulerTimeType.Stride
}

// MARK: - Device change observation
fileprivate extension CaptureSessionManager {
    /// if device selection changes reconfigure `captureSessiion`.
    func observeDeviceChangesAndReconfigureCaptureSession() {
        Publishers.MergeMany([
            Publishers.CombineLatest($videoInputDevice, $audioInputDevice).map { _ in () }.eraseToAnyPublisher(),
            $audioOutputDevice.map { _ in () }.eraseToAnyPublisher(),
        ])
        .throttle(for: captureSessionConfigurationThrottle, scheduler: DispatchQueue.main, latest: true)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in
            self?.reconfigureCaptureSession()
        }
        .store(in: &cancellable)
    }

    /// if device that we are using suddenly disconnects, unset it and rever to default if needed.
    func observeDisconnectionsAndFallbackIfNeeded() {
        deviceObservationService.captureDeviceDidDisconnect
            .receive(on: DispatchQueue.main)
            .sink { [weak self] disconnectedDevice in
                guard let self else { return }

                if disconnectedDevice.uniqueID == self.audioInputDevice?.uniqueID {
                    self.audioInputDevice = .none
                }

                if disconnectedDevice.uniqueID == self.videoInputDevice?.uniqueID {
                    self.videoInputDevice = .none
                }
                self.revertToDefaultDevicesIfNeeded()
            }
            .store(in: &cancellable)

        deviceObservationService.playbackDeviceDidDisconnect
            .receive(on: DispatchQueue.main)
            .sink { [weak self] disconnecteDevice in
                guard let self else { return }

                if disconnecteDevice.uniqueID == self.audioOutputDevice?.uniqueID {
                    self.audioOutputDevice = .none
                }
                self.revertToDefaultDevicesIfNeeded()
            }
            .store(in: &cancellable)
    }
}
