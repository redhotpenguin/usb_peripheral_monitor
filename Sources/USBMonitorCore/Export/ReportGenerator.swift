import Foundation

public struct DeviceReport: Sendable {
    public let generatedAt: Date
    public let totalDevices: Int
    public let byClass: [String: Int]
    public let bySpeed: [String: Int]
    public let recentEvents: [DeviceEvent]
    public let devices: [USBDevice]

    public var summaryText: String {
        var lines = [
            "USB Device Report",
            "Generated: \(DateFormatter.localizedString(from: generatedAt, dateStyle: .medium, timeStyle: .short))",
            "Total Devices: \(totalDevices)",
            "",
            "By Class:",
        ]
        for (cls, count) in byClass.sorted(by: { $0.value > $1.value }) {
            lines.append("  \(cls): \(count)")
        }
        lines.append("")
        lines.append("By Speed:")
        for (speed, count) in bySpeed.sorted(by: { $0.value > $1.value }) {
            lines.append("  \(speed): \(count)")
        }
        lines.append("")
        lines.append("Recent Activity (\(recentEvents.count) events):")
        for event in recentEvents.suffix(10) {
            let ts = DateFormatter.localizedString(from: event.timestamp, dateStyle: .none, timeStyle: .medium)
            lines.append("  [\(ts)] \(event.eventType.label)")
        }
        return lines.joined(separator: "\n")
    }
}

public enum ReportGenerator {
    public static func generate(devices: [USBDevice], events: [DeviceEvent]) -> DeviceReport {
        var byClass: [String: Int] = [:]
        var bySpeed: [String: Int] = [:]
        for d in devices {
            byClass[d.deviceClass.rawValue, default: 0] += 1
            bySpeed[d.speed.rawValue, default: 0] += 1
        }
        return DeviceReport(
            generatedAt: Date(),
            totalDevices: devices.count,
            byClass: byClass,
            bySpeed: bySpeed,
            recentEvents: events,
            devices: devices
        )
    }
}
