import SwiftUI
import USBMonitorCore

struct DeviceCardView: View {
    let device: USBDevice

    var body: some View {
        GroupBox {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconBackgroundColor.gradient)
                        .frame(width: 60, height: 60)
                    Image(systemName: device.deviceClass.systemImageName)
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(device.displayName)
                        .font(.title2.bold())

                    HStack(spacing: 8) {
                        Badge(text: device.deviceClass.rawValue, color: .blue)
                        Badge(text: device.speed.displayLabel, color: speedBadgeColor)
                        if let vendor = device.vendorName {
                            Badge(text: vendor, color: .secondary)
                        }
                    }

                    HStack(spacing: 16) {
                        LabeledValue(label: "Vendor ID", value: device.vendorIDHex)
                        LabeledValue(label: "Product ID", value: device.productIDHex)
                        if let serial = device.serialNumber {
                            LabeledValue(label: "Serial", value: serial)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(8)
        }
    }

    private var iconBackgroundColor: Color {
        switch device.deviceClass {
        case .hub: return .orange
        case .storage: return .blue
        case .hid: return .purple
        case .audio: return .pink
        case .usbC: return .teal
        case .video: return .indigo
        default: return .gray
        }
    }

    private var speedBadgeColor: Color {
        switch device.speed {
        case .usb4Gen3, .usb4Gen2: return .green
        case .superSpeedPlus, .superSpeed: return .blue
        case .highSpeed: return .yellow
        default: return .secondary
        }
    }
}

struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct LabeledValue: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).foregroundStyle(.tertiary)
            Text(value).foregroundStyle(.secondary)
        }
    }
}
