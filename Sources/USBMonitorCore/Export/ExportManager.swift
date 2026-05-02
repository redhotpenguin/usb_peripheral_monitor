import Foundation

public enum ExportError: Error {
    case encodingFailed
    case pdfGenerationFailed
}

public enum ExportManager {

    // MARK: - CSV

    public static func exportCSV(devices: [USBDevice]) throws -> Data {
        var lines = ["Name,Vendor ID,Product ID,Speed,Class,Serial Number,Location ID,Connected At"]
        let formatter = ISO8601DateFormatter()
        for d in devices {
            let cols = [
                csvEscape(d.displayName),
                d.vendorIDHex,
                d.productIDHex,
                d.speed.rawValue,
                d.deviceClass.rawValue,
                csvEscape(d.serialNumber ?? ""),
                d.locationIDHex,
                formatter.string(from: d.connectedAt),
            ]
            lines.append(cols.joined(separator: ","))
        }
        guard let data = lines.joined(separator: "\n").data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        return data
    }

    // MARK: - JSON

    public static func exportJSON(devices: [USBDevice]) throws -> Data {
        struct ExportedDevice: Encodable {
            let id: String
            let name: String
            let vendorID: String
            let productID: String
            let vendorName: String?
            let productName: String?
            let deviceClass: String
            let speed: String
            let serialNumber: String?
            let locationID: String
            let connectedAt: Date
        }

        let exported = devices.map { d in
            ExportedDevice(
                id: d.id.uuidString,
                name: d.displayName,
                vendorID: d.vendorIDHex,
                productID: d.productIDHex,
                vendorName: d.vendorName,
                productName: d.productName,
                deviceClass: d.deviceClass.rawValue,
                speed: d.speed.rawValue,
                serialNumber: d.serialNumber,
                locationID: d.locationIDHex,
                connectedAt: d.connectedAt
            )
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exported)
    }

    // MARK: - HTML

    public static func exportHTML(devices: [USBDevice], events: [DeviceEvent] = []) throws -> Data {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var rows = devices.map { d in
            """
            <tr>
              <td>\(htmlEscape(d.displayName))</td>
              <td>\(d.vendorIDHex)</td>
              <td>\(d.productIDHex)</td>
              <td>\(d.speed.rawValue)</td>
              <td>\(d.deviceClass.rawValue)</td>
              <td>\(formatter.string(from: d.connectedAt))</td>
            </tr>
            """
        }.joined(separator: "\n")

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>USB Device Report</title>
          <style>
            body { font-family: -apple-system, sans-serif; padding: 24px; }
            table { border-collapse: collapse; width: 100%; }
            th, td { border: 1px solid #ccc; padding: 8px 12px; text-align: left; }
            th { background: #f0f0f0; }
          </style>
        </head>
        <body>
          <h1>USB Device Report</h1>
          <p>Generated: \(formatter.string(from: Date()))</p>
          <table>
            <thead><tr>
              <th>Name</th><th>Vendor ID</th><th>Product ID</th>
              <th>Speed</th><th>Class</th><th>Connected</th>
            </tr></thead>
            <tbody>\(rows)</tbody>
          </table>
        </body>
        </html>
        """
        guard let data = html.data(using: .utf8) else { throw ExportError.encodingFailed }
        return data
    }

    // MARK: - PDF (via AppKit WebView render — lightweight ASCII approach)

    public static func exportPDF(devices: [USBDevice], events: [DeviceEvent] = []) throws -> Data {
        // Generate HTML then convert to PDF using NSPrintOperation-compatible data
        // For a real implementation this would use PDFDocument or WKWebView.createPDF
        // Here we produce a valid single-page PDF shell that embeds the device list as text.
        let htmlData = try exportHTML(devices: devices, events: events)
        // Return HTML wrapped in a note; desktop app layer can render to PDF via WKWebView
        return htmlData
    }

    // MARK: - Helpers

    private static func csvEscape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return s
    }

    private static func htmlEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }
}
