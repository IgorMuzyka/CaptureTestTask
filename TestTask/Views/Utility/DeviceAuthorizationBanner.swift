
import AVFoundation
import SwiftUI
import SFSafeSymbols
import Factory

struct DeviceAuthorizationBanner: View {
    @InjectedObject(\.deviceAuthorizationHelper) private var deviceAuthorizationHelper
    let mediaType: AVMediaType

    var body: some View {
        if let authorizationStatus, authorizationStatus != .authorized {
            LabeledContent("Permission required") {
                if canAskUserForAccess {
                    grantAccessButton
                } else if canUserChangeAccessFromSystemSettings {
                    gotToSystemPreferenceButton
                } else {
                    canNeitherRaiseNorGrantAccessBanner
                }
            }
        }
    }

    @ViewBuilder private var grantAccessButton: some View {
        Button(action: promptUserForAccess) {
            Text("Grant")
                .fontWeight(.semibold)
        }
        .buttonStyle(.bordered)
        .foregroundStyle(Color.accentColor)
    }

    @ViewBuilder private var gotToSystemPreferenceButton: some View {
        Link(destination: preferencePaneURL) {
            Text("Go to System Settings")
                .fontWeight(.semibold)
        }
        .buttonStyle(.bordered)
        .foregroundStyle(Color.accentColor)
    }

    @ViewBuilder private var canNeitherRaiseNorGrantAccessBanner: some View {
        Text(
            """
            Current user can neither raise nor grant required permissions. 
            Please ask you system administrator to adjust the app privacy settings.
            """
        )
        .lineLimit(.none)
        .fontWeight(.semibold)
    }

    private func promptUserForAccess() {
        Task { [weak deviceAuthorizationHelper] in
            await deviceAuthorizationHelper?.raiseAuthorizationStatusIfNeeded(for: mediaType)
        }
    }
}

// MARK: - Convenience
fileprivate extension DeviceAuthorizationBanner {
    var preferencePaneURL: URL! {
        switch mediaType {
            case .audio: PreferencePane.microphoneSettingsURL
            case .video: PreferencePane.cameraSettingsURL
            default: .none
        }
    }

    var authorizationStatus: AVAuthorizationStatus! {
        switch mediaType {
            case .audio: deviceAuthorizationHelper.audioAuthorizationStatus
            case .video: deviceAuthorizationHelper.videoAuthorizationStatus
            default: .none
        }
    }

    var canUserChangeAccessFromSystemSettings: Bool {
        authorizationStatus.canBeRaised && !canAskUserForAccess
    }

    var canAskUserForAccess: Bool {
        !authorizationStatus.hasPreviouslyRequestedAccess
    }
}

fileprivate extension AVAuthorizationStatus {
    var canBeRaised: Bool {
        guard case .restricted = self else { return true }
        return false
    }
    
    var hasPreviouslyRequestedAccess: Bool {
        guard case .notDetermined = self else { return true }
        return false
    }
}

extension AVAuthorizationStatus: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
            case .notDetermined: return "Not determined" // haven't asked yet
            case .restricted: return "Restricted" // no access, user can't raise
            case .denied: return "Denied" // denied, can raise
            case .authorized: return "Authorized" // granted
            @unknown default: return "@unknown"
        }
    }
}
