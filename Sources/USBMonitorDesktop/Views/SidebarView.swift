import SwiftUI
import USBMonitorCore

struct SidebarView: View {
    @EnvironmentObject var sidebarController: SidebarController
    @EnvironmentObject var deviceWatcher: USBDeviceWatcher
    @Binding var selection: SidebarSelection?

    // Highest speed at top, lowest at bottom
    private let speedTiers: [USBSpeed] = [
        .usb4Gen3, .usb4Gen2, .superSpeedPlus, .superSpeed,
        .highSpeed, .fullSpeed, .lowSpeed
    ]

    var body: some View {
        List(selection: $selection) {
            Section("Smart Groups") {
                SmartGroupRow(
                    title: "All Devices",
                    icon: "rectangle.connected.to.line.below",
                    count: deviceWatcher.devices.count
                )
                .tag(SidebarSelection.allDevices)

                SmartGroupRow(
                    title: "Recently Connected",
                    icon: "clock.arrow.circlepath",
                    count: sidebarController.recentlyConnected.count
                )
                .tag(SidebarSelection.recentlyConnected)

                ForEach(speedTiers, id: \.self) { tier in
                    SmartGroupRow(
                        title: tier.rawValue,
                        icon: speedIcon(for: tier),
                        count: sidebarController.devices(at: tier).count
                    )
                    .tag(SidebarSelection.speed(tier))
                }
            }

            ForEach(sidebarController.sections) { section in
                Section(section.title) {
                    ForEach(section.devices) { device in
                        DeviceRow(device: device)
                            .tag(SidebarSelection.device(device.id))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("USB Monitor")
    }

    private func speedIcon(for speed: USBSpeed) -> String {
        switch speed {
        case .usb4Gen3:       return "bolt.fill"
        case .usb4Gen2:       return "bolt"
        case .superSpeedPlus: return "arrow.up.forward.circle.fill"
        case .superSpeed:     return "arrow.up.forward.circle"
        case .highSpeed:      return "hare"
        case .fullSpeed:      return "figure.walk"
        case .lowSpeed:       return "tortoise"
        case .unknown:        return "questionmark.circle"
        }
    }
}

private struct SmartGroupRow: View {
    let title: String
    let icon: String
    let count: Int

    var body: some View {
        Label {
            HStack {
                Text(title)
                Spacer()
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.blue)
        }
    }
}

private struct DeviceRow: View {
    let device: USBDevice

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(device.displayName)
                    .font(.body)
                    .lineLimit(1)
                Text(device.speed.displayLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: device.deviceClass.systemImageName)
                .foregroundStyle(iconColor)
        }
    }

    private var iconColor: Color {
        switch device.deviceClass {
        case .hub: return .orange
        case .storage: return .blue
        case .hid: return .purple
        case .audio: return .pink
        case .usbC: return .teal
        default: return .secondary
        }
    }
}
