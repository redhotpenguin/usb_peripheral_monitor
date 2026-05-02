import Foundation

public struct PDO: Sendable {
    public enum PDOType: String, Sendable {
        case fixed, battery, variable, programmable
    }

    public let type: PDOType
    public let voltageV: Double
    public let currentA: Double
    public let maxPowerW: Double

    public var displayLabel: String {
        String(format: "%.0fV / %.1fA (%.0fW)", voltageV, currentA, maxPowerW)
    }
}

public enum PDOParser {
    public static func parse(rawPDOs: [UInt32]) -> [PDO] {
        rawPDOs.compactMap { parseSingle($0) }
    }

    private static func parseSingle(_ raw: UInt32) -> PDO? {
        let typeRaw = (raw >> 30) & 0x3
        switch typeRaw {
        case 0: // Fixed
            let voltage = Double((raw >> 10) & 0x3FF) * 0.05
            let current = Double(raw & 0x3FF) * 0.01
            return PDO(type: .fixed, voltageV: voltage, currentA: current, maxPowerW: voltage * current)
        case 1: // Battery
            let maxVoltage = Double((raw >> 20) & 0x3FF) * 0.05
            let minVoltage = Double((raw >> 10) & 0x3FF) * 0.05
            let maxPower = Double(raw & 0x3FF) * 0.25
            return PDO(type: .battery, voltageV: (maxVoltage + minVoltage) / 2, currentA: 0, maxPowerW: maxPower)
        case 2: // Variable
            let maxVoltage = Double((raw >> 20) & 0x3FF) * 0.05
            let current = Double(raw & 0x3FF) * 0.01
            return PDO(type: .variable, voltageV: maxVoltage, currentA: current, maxPowerW: maxVoltage * current)
        case 3: // Programmable (APDO)
            let maxVoltage = Double((raw >> 17) & 0xFF) * 0.1
            let maxCurrent = Double(raw & 0x7F) * 0.05
            return PDO(type: .programmable, voltageV: maxVoltage, currentA: maxCurrent, maxPowerW: maxVoltage * maxCurrent)
        default:
            return nil
        }
    }
}
