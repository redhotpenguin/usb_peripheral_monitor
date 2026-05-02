import SwiftUI
import USBMonitorCore

struct EventHistoryTable: View {
    let events: [DeviceEvent]

    var body: some View {
        GroupBox("Event History") {
            if events.isEmpty {
                Text("No events recorded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                Table(events.reversed()) {
                    TableColumn("Time") { event in
                        Text(event.timestamp, style: .time)
                            .font(.caption.monospacedDigit())
                    }
                    .width(min: 80, ideal: 100)

                    TableColumn("Type") { event in
                        HStack(spacing: 4) {
                            Image(systemName: event.eventType.systemImageName)
                                .foregroundStyle(event.eventType == .attach ? .green : .red)
                            Text(event.eventType.label)
                        }
                        .font(.caption)
                    }
                    .width(min: 100, ideal: 120)

                    TableColumn("Location ID") { event in
                        Text(String(format: "0x%08X", event.locationID))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minHeight: 120, maxHeight: 240)
            }
        }
    }
}
