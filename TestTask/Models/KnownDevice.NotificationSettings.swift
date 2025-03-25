
extension KnownDevice {
    struct NotificationSettings: Codable {
        public var shouldTrackNewDeviceConnections: Bool
        public var shouldTrackDeviceConnectins: Bool
        public var shouldTrackDeviceDisconnections: Bool

        init(
            shouldTrackNewDeviceConnections: Bool = true,
            shouldTrackDeviceConnectins: Bool = false,
            shouldTrackDeviceDisonnections: Bool = false
        ) {
            self.shouldTrackNewDeviceConnections = shouldTrackNewDeviceConnections
            self.shouldTrackDeviceConnectins = shouldTrackDeviceConnectins
            self.shouldTrackDeviceDisconnections = shouldTrackDeviceDisonnections
        }
    }
}
