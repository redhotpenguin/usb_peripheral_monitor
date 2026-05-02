import SwiftUI
import Charts
import USBMonitorCore

struct InspectorView: View {
    let device: USBDevice?
    @EnvironmentObject var inspectorController: InspectorController

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let device {
                    QuickInfoSection(device: device)
                    Divider()
                    RawPropertiesSection(device: device)
                    Divider()
                    LiveGraphsSection(controller: inspectorController)
                } else {
                    Text("No device selected")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .padding(12)
        }
        .background(.regularMaterial)
    }
}

// MARK: - Quick Info

struct QuickInfoSection: View {
    let device: USBDevice

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Info")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                InfoRow(label: "Vendor ID", value: device.vendorIDHex)
                InfoRow(label: "Product ID", value: device.productIDHex)
                InfoRow(label: "Speed", value: device.speed.displayLabel)
                InfoRow(label: "Location", value: device.locationIDHex)
                if let serial = device.serialNumber {
                    InfoRow(label: "Serial", value: serial)
                }
                if let vendor = device.vendorName {
                    InfoRow(label: "Vendor", value: vendor)
                }
            }
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        GridRow {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.trailing)
            Text(value)
                .font(.caption.monospaced())
                .gridColumnAlignment(.leading)
        }
    }
}

// MARK: - Raw Properties

struct RawPropertiesSection: View {
    let device: USBDevice
    @State private var expanded = false

    var body: some View {
        DisclosureGroup("Technical Details", isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 4) {
                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
                    InfoRow(label: "Class", value: device.deviceClass.rawValue)
                    InfoRow(label: "Connected", value: device.connectedAt.formatted(date: .abbreviated, time: .shortened))
                    if let parent = device.parentHub {
                        InfoRow(label: "Parent Hub", value: String(parent.uuidString.prefix(8)) + "…")
                    }
                }
            }
            .padding(.top, 4)
        }
        .font(.caption)
    }
}

// MARK: - Live Graphs

struct LiveGraphsSection: View {
    @ObservedObject var controller: InspectorController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Live Power")
                .font(.headline)

            if controller.powerSamples.isEmpty {
                Text("Waiting for data…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 80)
            } else {
                Chart(controller.powerSamples) { sample in
                    LineMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("Watts", sample.watts)
                    )
                    .foregroundStyle(.green)
                    AreaMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("Watts", sample.watts)
                    )
                    .foregroundStyle(.green.opacity(0.15))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(String(format: "%.0fW", v))
                            }
                        }
                    }
                }
                .frame(height: 80)
            }

            if let source = controller.currentPower {
                HStack {
                    Text("Current:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(source.displayWatts)
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }
        }
    }
}
