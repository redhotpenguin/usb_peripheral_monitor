import SwiftUI
import USBMonitorCore

struct ExportMenuButton: View {
    let devices: [USBDevice]
    @State private var showExportSheet = false

    var body: some View {
        Button {
            showExportSheet = true
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(devices: devices)
        }
    }
}
