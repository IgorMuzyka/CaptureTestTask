
import AVFoundation

public final class DeviceAuthorizationHelper: ObservableObject {
    @Published private(set) var videoAuthorizationStatus: AVAuthorizationStatus
    @Published private(set) var audioAuthorizationStatus: AVAuthorizationStatus

    public init(
        audioAuthorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio),
        videoAuthorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    ) {
        self.audioAuthorizationStatus = audioAuthorizationStatus
        self.videoAuthorizationStatus = videoAuthorizationStatus
    }

    public func raiseAuthorizationStatusIfNeeded(for mediaType: AVMediaType) async {
        switch mediaType {
            case .audio: await raiseAudioAuthorizationStatusIfNeeded()
            case .video: await raiseVideoAuthorizationStatusIfNeeded()
            default: break
        }
    }

    public func raiseAudioAuthorizationStatusIfNeeded() async {
        guard case .notDetermined = audioAuthorizationStatus else { return }
        _ = await AVCaptureDevice.requestAccess(for: .audio)
        audioAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    }

    public func raiseVideoAuthorizationStatusIfNeeded() async {
        guard case .notDetermined = videoAuthorizationStatus else { return }
        _ = await AVCaptureDevice.requestAccess(for: .video)
        videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
}
