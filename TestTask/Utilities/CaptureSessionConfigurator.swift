
import AVFoundation

struct CaptureSessionConfigurator {
    private let captureSession: AVCaptureSession
    private let sessionDeviceInputs: Set<AVCaptureDeviceInput>

    init(captureSession: AVCaptureSession) {
        self.captureSession = captureSession
        self.sessionDeviceInputs = Set(captureSession.inputs.compactMap { $0 as? AVCaptureDeviceInput })
    }

    @discardableResult
    func reconfigure(
        videoInputDevice: AVCaptureDevice?,
        audioInputDevice: AVCaptureDevice?,
        videouDataOutput: AVCaptureVideoDataOutput?
    ) -> [Error]? {
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
        }
        var errors: [Error] = []
        do throws(Error) {
            try addOrRemove(device: videoInputDevice, mediaType: .video)
        } catch {
            errors.append(error)
        }
        do throws(Error) {
            try addOrRemove(device: audioInputDevice, mediaType: .audio)
        } catch {
            errors.append(error)
        }
        do throws(Error) {
            try addOrRemoveOutput(output: videouDataOutput)
        } catch {
            errors.append(error)
        }
        guard errors.isEmpty else { return errors }
        return .none
    }
}

// MARK: - Input/Output manipulation
fileprivate extension CaptureSessionConfigurator {
    func addOrRemoveOutput(output: AVCaptureVideoDataOutput?) throws(Error) {
        if let previous = captureSession.outputs.compactMap({ $0 as? AVCaptureVideoDataOutput }).first {
            captureSession.removeOutput(previous)
        }
        guard let output else { return }
        guard captureSession.canAddOutput(output) else {
            throw .canNotAddVideoDataOutput
        }
        captureSession.addOutput(output)
        guard case .some = output.connection(with: .video) else {
            throw .failedToCreateConnectionToVideoDataOutput
        }
    }

    func addOrRemove(device: AVCaptureDevice?, mediaType: AVMediaType) throws(Error) {
        if let device {
            guard case .none = sessionDeviceInputs.first(where: { $0.device.uniqueID == device.uniqueID }) else {
                return // already added, do nothing
            }
            let input: AVCaptureDeviceInput
            do {
                input = try AVCaptureDeviceInput(device: device)
            } catch {
                throw .failedToCreateInput(deviceId: device.uniqueID, underlyingError: error)
            }
            guard captureSession.canAddInput(input) else {
                throw .canNotAddDeviceAsInput(deviceId: device.uniqueID)
            }
            removeInput(by: mediaType)
            captureSession.addInput(input)
        } else {
            removeInput(by: mediaType)
        }
    }

    func removeInput(by mediaType: AVMediaType) {
        guard let input = sessionDeviceInputs.first(where: { $0.device.hasMediaType(mediaType) }) else {
            return // not in inputs, do nothing
        }
        captureSession.removeInput(input)
    }
}

// MARK: - Error
extension CaptureSessionConfigurator {
    enum Error: Swift.Error, LocalizedError {
        case failedToCreateInput(deviceId: String, underlyingError: any Swift.Error)
        case canNotAddDeviceAsInput(deviceId: String)
        case canNotAddVideoDataOutput
        case failedToCreateConnectionToVideoDataOutput

        var errorDescription: String? {
            switch self {
                case .failedToCreateInput(let deviceId, let underlyingError):
                    "failed to create input: device(\(deviceId)), error: \(underlyingError.localizedDescription)"
                case .canNotAddDeviceAsInput(let deviceId):
                    "can not add as input: device(\(deviceId))"
                case .canNotAddVideoDataOutput:
                    "can not add video data output"
                case .failedToCreateConnectionToVideoDataOutput:
                    "failed to create connection to video data output"
            }
        }
    }
}
