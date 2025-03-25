
import SwiftUI
import AVFoundation
import SFSafeSymbols
import Factory

struct ConferenceSettingsView: View {
    @InjectedObject(\.deviceAuthorizationHelper) private var deviceAuthorizationHelper
    @InjectedObject(\.deviceObservationService) private var deviceObservationService
    @InjectedObject(\.userNotificationService) private var userNotificationService
    @InjectedObject(\.captureSessionManager) private var captureSessionManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ZStack {
            Rectangle().fill(.clear)
            settingsForm
        }
        .frame(minWidth: 380)
        .toolbar { toolbarContent }
        .task {
            do {
                try await userNotificationService.requestAuthorization()
            } catch {
                #if DEBUG
                print(error.localizedDescription)
                #endif
            }
        }
    }

    @ViewBuilder private var settingsForm: some View {
        Form {
            videoSection
            Divider()
            audioSection
        }
        .padding()
    }

    @ViewBuilder private var videoSection: some View {
        Section {
            pickerMenu(
                title: "Input",
                selection: $captureSessionManager.videoInputDevice,
                options: deviceObservationService.videoInputDevices,
                description: \.!.localizedName
            )
            pickerMenu(
                title: "Filter",
                selection: $captureSessionManager.videoFilter,
                options: VideoFilter.allCases,
                description: \.rawValue
            )
        } header: {
            sectionHeder(title: "Video", symbol: .videoFill)
        } footer: {
            DeviceAuthorizationBanner(mediaType: .video)
        }
    }

    @ViewBuilder private var audioSection: some View {
        Section {
            pickerMenu(
                title: "Input",
                selection: $captureSessionManager.audioInputDevice,
                options: deviceObservationService.audioInputDevices,
                description: \.!.localizedName
            )
            pickerMenu(
                title: "Output",
                selection: $captureSessionManager.audioOutputDevice,
                options: deviceObservationService.audioOutputDevices,
                description: \.!.name
            )
        } header: {
            sectionHeder(title: "Audio", symbol: .speakerWave3Fill)
        } footer: {
            DeviceAuthorizationBanner(mediaType: .audio)
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Devices", action: showDevices)
                .buttonStyle(.bordered)
        }
        ToolbarItem(placement: .cancellationAction) {
            Button("Preview", action: showPreview)
                .buttonStyle(.bordered)
                .disabled(!isPreviewAvailable)
        }
    }
}

// MARK: - Convenience
fileprivate extension ConferenceSettingsView {
    func showPreview() {
        captureSessionManager.isPreviewEnabled = true
        openWindow(App.Window.cameraPreview)
    }

    func showDevices() {
        openWindow(App.Window.knownDevices)
    }

    var isPreviewAvailable: Bool {
        !captureSessionManager.isPreviewEnabled
        && (
            /// it only makes sence to disallow camer preview if there's no access to camera
            deviceAuthorizationHelper.videoAuthorizationStatus == .authorized
//            || deviceAuthorizationHelper.audioAuthorizationStatus == .authorized
        )
    }

    @ViewBuilder func sectionHeder(
        title: LocalizedStringKey,
        symbol: SFSymbol
    ) -> some View {
        Label(title, systemSymbol: symbol)
            .labelStyle(.titleAndIcon)
            .font(.title2)
            .fontWeight(.bold)
    }

    @ViewBuilder func pickerMenu<Item: Hashable>(
        title: LocalizedStringKey,
        selection: Binding<Item>,
        options: [Item],
        description: KeyPath<Item, String>
    ) -> some View {
        LabeledContent(title) {
            Picker(
                selection: selection,
                content: {
                    ForEach(options, id: \.hashValue) { item in
                        let title = item[keyPath: description]
                        Text(title)
                            .tag(item)
                    }
                },
                label: { }
            )
            /// if it's one single device user has no choice
            .disabled(options.count <= 1)
        }
    }
}
