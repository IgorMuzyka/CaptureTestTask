
import Factory

// MARK: - Services
extension Container {
    var knownDevicesManager: Factory<KnownDevicesManager> {
        self { KnownDevicesManager() }.singleton
    }
    
    var deviceObservationService: Factory<DeviceObservationService> {
        self { DeviceObservationService() }.shared
    }

    var userNotificationService: Factory<UserNotificationService> {
        self { UserNotificationService() }.shared
    }

    var captureSessionManager: Factory<CaptureSessionManager> {
        self { CaptureSessionManager() }.shared
    }

    var videoProcessor: Factory<VideoProcessor> {
        self { VideoProcessor() }.shared
    }
}

// MARK: - Utilities
extension Container {
    var captureDeviceObserver: Factory<CaptureDeviceObserver> {
        self { CaptureDeviceObserver() }.shared
    }

    var playbackDeviceObserver: Factory<PlaybackDeviceObserver> {
        self { PlaybackDeviceObserver() }.shared
    }

    var deviceAuthorizationHelper: Factory<DeviceAuthorizationHelper> {
        self { DeviceAuthorizationHelper() }.shared
    }
}

// MARK: - AVCaptureSession
import AVFoundation

extension Container {
    var captureSession: Factory<AVCaptureSession> {
        self { AVCaptureSession() }.shared
    }
}
