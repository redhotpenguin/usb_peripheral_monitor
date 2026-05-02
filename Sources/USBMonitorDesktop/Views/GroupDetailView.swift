import SwiftUI
import USBMonitorCore

struct GroupDetailView: View {
    let title: String
    let devices: [USBDevice]

    @State private var sortOrder = [KeyPathComparator(\USBDevice.displayName)]
    @State private var selectedID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.title2.bold())
                Spacer()
                Text("\(devices.count) device\(devices.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            if devices.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No devices")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                Table(devices, selection: $selectedID, sortOrder: $sortOrder) {
                    TableColumn("Name", value: \.displayName) { device in
                        Label {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(device.displayName)
                                    .lineLimit(1)
                                if let vendor = device.vendorName {
                                    Text(vendor)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: device.deviceClass.systemImageName)
                                .foregroundStyle(.blue)
                        }
                    }

                    TableColumn("Class", value: \.deviceClass.rawValue)
                        .width(min: 80, ideal: 100)

                    TableColumn("Speed") { device in
                        Text(device.speed.displayLabel)
                    }
                    .width(min: 140, ideal: 180)

                    TableColumn("Vendor ID") { device in
                        Text(device.vendorIDHex)
                            .font(.body.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .width(min: 80, ideal: 90)

                    TableColumn("Product ID") { device in
                        Text(device.productIDHex)
                            .font(.body.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .width(min: 80, ideal: 90)

                    TableColumn("Connected") { device in
                        Text(device.connectedAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .width(min: 80, ideal: 100)
                }
            }
        }
    }
}
