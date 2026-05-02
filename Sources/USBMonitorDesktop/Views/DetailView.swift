import SwiftUI
import USBMonitorCore

struct DetailView: View {
    let device: USBDevice?
    @EnvironmentObject var detailController: DetailController

    var body: some View {
        if let device {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DeviceCardView(device: device)
                    TimelineView(device: device, events: detailController.events)
                    EventHistoryTable(events: detailController.events)
                }
                .padding()
            }
            .onChange(of: device.id) { _ in
                detailController.load(for: device)
            }
            .onAppear {
                detailController.load(for: device)
            }
        } else {
            EmptyDetailView()
        }
    }
}

struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "cable.connector")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Select a Device")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Choose a device from the sidebar to view details.")
                .font(.body)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
