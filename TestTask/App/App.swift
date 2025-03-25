
import SwiftUI
import Factory

@main
struct App: SwiftUI.App {
    @NSApplicationDelegateAdaptor(Self.Delegate.self) private var delegate
    /// for the sake of notifications it's instantiated here, though never directly used here
    @InjectedObject(\.knownDevicesManager) private var knownDevicesManager

    var body: some Scene {
        /// Conference Settings
        WindowGroup(uniqueWindow: Window.conferenceSettings) {
            ConferenceSettingsView()
                .background(windowBackground)
        }
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unifiedCompact(showsTitle: true))

        /// Camera Preview
        WindowGroup(uniqueWindow: Window.cameraPreview) {
            CapturePreviewView()
                .background(windowBackground)
        }
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unifiedCompact(showsTitle: true))

        /// Known Devices
        WindowGroup(uniqueWindow: Window.knownDevices) {
            KnownDevicesTableView()
                .background(windowBackground)
        }
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unifiedCompact(showsTitle: true))
    }

    /// A nice see-through(barely) frosted glass effect as window background.
    /// Window reconfiguration as a bonus, but misbehaves sometimes.
    @ViewBuilder private var windowBackground: some View {
        FrozenGlassWindowEffect.reconfiguringWindow(state: .active) { window in
            window.center()
            window.titlebarAppearsTransparent = true
            window.isRestorable = false
        }
        .ignoresSafeArea(.all, edges: .all)
    }
}
