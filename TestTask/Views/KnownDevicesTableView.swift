
import SwiftUI
import SFSafeSymbols
import Factory

struct KnownDevicesTableView: View {
    @InjectedObject(\.knownDevicesManager) private var knownDevicesManager

    var body: some View {
        ZStack {
            Rectangle().fill(.clear)
            VStack {
                settings
                table
            }
        }
    }

    @ViewBuilder private var settings: some View {
        Form {
            Section {
                Toggle(isOn: $knownDevicesManager.notificationSettings.shouldTrackNewDeviceConnections) {
                    Text("Notify when **new** device **connnects**.")
                }
                Toggle(isOn: $knownDevicesManager.notificationSettings.shouldTrackDeviceConnectins) {
                    Text("Notify when **tracked** device **connnects**.")
                }
                Toggle(isOn: $knownDevicesManager.notificationSettings.shouldTrackDeviceDisconnections) {
                    Text("Notify when **tracked** device **disconnects**.")
                }
            } header: {
                let symbol: SFSymbol = knownDevicesManager.notificationSettings.isAllDisabled ? .bellSlashFill : .bellFill
                Label("Device connection notification settings", systemSymbol: symbol)
                    .labelStyle(.titleAndIcon)
                    .font(.title2)
                    .fontWeight(.bold)
            } footer: {
                Label {
                    Text("**Check** boxes for **devices** below to be **notified** when device connection changes.")
                        .lineLimit(.none)
                } icon: {
                    Image(systemSymbol: .info)
                        .foregroundStyle(.blue)
                        .frame(alignment: .leadingLastTextBaseline)
                }
                .lineLimit(.none)
                .labelStyle(.titleAndIcon)
                .padding(.vertical)
            }
        }
        .frame(width: .infinity)
        .padding()
    }

    @ViewBuilder private var table: some View {
        Table(knownDevicesManager.devices) {
            TableColumn("Should Notify") { device in
                Toggle(isOn: knownDevicesManager.tracking(device)) {}
            }
            .width(min: 80, max: 80)
            TableColumn("Device Name", value: \.name)
                .width(min: 160)
            TableColumn("Media Type", value: \.mediaType.description)
                .width(min: 80, max: 80)
            TableColumn("Buffer Type", value: \.bufferType.description)
                .width(min: 80, max: 80)
            TableColumn("Is Connected") { device in
                connectionIndicator(for: device)
            }
            .width(min: 80, max: 80)
        }
        .id(knownDevicesManager.refreshToken)
        .tableColumnHeaders(.visible)
    }

    @ViewBuilder private func connectionIndicator(for device: KnownDevice) -> some View {
        let isConnected = device.isConnected ? "Yes" : "No"
        let color: Color = device.isConnected ? .green : .primary
        let symbol: SFSymbol = device.isConnected ? .power : .poweroff
        Label {
            Text(isConnected)
        } icon: {
            Image(systemSymbol: symbol)
                .foregroundStyle(color)
        }
    }
}

fileprivate extension KnownDevice.NotificationSettings {
    var isAllDisabled: Bool {
        let flags = [
            shouldTrackNewDeviceConnections,
            shouldTrackDeviceConnectins,
            shouldTrackDeviceDisconnections,
        ]
        return !flags.contains(true)
    }
}
