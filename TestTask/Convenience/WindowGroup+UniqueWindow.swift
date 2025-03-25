
import SwiftUI

/// borrowed and adapted from [here](https://www.fline.dev/window-management-on-macos-with-swiftui-4/)
extension WindowGroup {
    init<WindowType: Identifiable, WindowContent: View>(
        uniqueWindow: WindowType,
        @ViewBuilder content: @escaping () -> WindowContent
    ) where WindowType.ID == String, Content == PresentedWindowContent<String, WindowContent> {
        self.init(uniqueWindow.id, id: uniqueWindow.id, for: String.self) { _ in
            content()
        } defaultValue: {
            uniqueWindow.id
        }
    }
}

extension OpenWindowAction {
    func callAsFunction<WindowType: Identifiable>(_ window: WindowType) where WindowType.ID == String {
        callAsFunction(id: window.id, value: window.id)
    }
}
