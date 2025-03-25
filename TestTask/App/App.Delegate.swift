
import SwiftUI
import AppKit

extension App {
    final class Delegate: NSObject, NSApplicationDelegate {
        func applicationDidFinishLaunching(_ notification: Notification) {
            /// i don't want this behavior.
            NSWindow.allowsAutomaticWindowTabbing = false
        }

        ///`SwiftUI.App` app will go on living without window by default.
        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            true
        }
    }
}

