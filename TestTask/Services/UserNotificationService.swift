
import UserNotifications

final class UserNotificationService: ObservableObject {
    private var isAuthorized: Bool = false

    public func requestAuthorization(options: UNAuthorizationOptions = [.alert, .badge, .sound]) async throws {
        let notificationCenter = UNUserNotificationCenter.current()
        isAuthorized = try await notificationCenter.requestAuthorization(options: options)
        guard isAuthorized else { return }
        notificationCenter.removeAllDeliveredNotifications()
    }

    func submit(_ update: KnownDevice.StatusUpdate) {
        let content = update.notificationContent
        #if DEBUG
        print(content.title, content.subtitle)
        #endif
        guard isAuthorized else { return }
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 0.25,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        /// Contemporary `macOS` might decide to **not show** notifications depending on `Focus` settings.
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Convenience
fileprivate extension KnownDevice.StatusUpdate {
    var notificationContent: UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let mediaType = device.mediaType.description
        let bufferType = device.bufferType.description
        let status = device.isConnected ? "Connected" : "Disconnected"

        var message = "\(mediaType) \(bufferType) Device \(status)"
        if isNew {
            message = "New " + message
        }
        content.title = message
        content.subtitle = device.name
        content.sound = UNNotificationSound.default

        return content
    }
}
