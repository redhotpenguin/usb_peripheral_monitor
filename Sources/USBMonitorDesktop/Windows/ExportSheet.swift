import SwiftUI
import AppKit
import UniformTypeIdentifiers
import USBMonitorCore

enum ExportFormat: String, CaseIterable, Identifiable {
    case csv = "CSV"
    case json = "JSON"
    case html = "HTML"

    var id: String { rawValue }
    var fileExtension: String { rawValue.lowercased() }
    var utType: UTType {
        switch self {
        case .csv: return .commaSeparatedText
        case .json: return .json
        case .html: return .html
        }
    }
}

struct ExportSheet: View {
    let devices: [USBDevice]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFormat: ExportFormat = .csv
    @State private var isExporting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Format") {
                    Picker("Export format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases) { fmt in
                            Text(fmt.rawValue).tag(fmt)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Summary") {
                    LabeledContent("Devices", value: "\(devices.count)")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Export Devices")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") { performExport() }
                        .disabled(isExporting || devices.isEmpty)
                }
            }
        }
        .frame(minWidth: 360, minHeight: 260)
    }

    private func performExport() {
        isExporting = true
        errorMessage = nil

        let data: Data
        do {
            switch selectedFormat {
            case .csv: data = try ExportManager.exportCSV(devices: devices)
            case .json: data = try ExportManager.exportJSON(devices: devices)
            case .html: data = try ExportManager.exportHTML(devices: devices)
            }
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            isExporting = false
            return
        }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "usb-devices.\(selectedFormat.fileExtension)"
        panel.allowedContentTypes = [selectedFormat.utType]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try data.write(to: url)
                    dismiss()
                } catch {
                    errorMessage = "Save failed: \(error.localizedDescription)"
                }
            }
            isExporting = false
        }
    }
}
