import Foundation

public struct PowerSource: Identifiable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let currentWatts: Double
    public let voltageV: Double
    public let amperageA: Double
    public let maxWatts: Double
    public let isCharging: Bool
    public let timestamp: Date

    public var displayWatts: String {
        currentWatts > 0 ? String(format: "%.1f W", currentWatts) : "—"
    }

    public init(
        id: UUID = UUID(),
        name: String,
        currentWatts: Double = 0,
        voltageV: Double = 0,
        amperageA: Double = 0,
        maxWatts: Double = 0,
        isCharging: Bool = false,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.currentWatts = currentWatts
        self.voltageV = voltageV
        self.amperageA = amperageA
        self.maxWatts = maxWatts
        self.isCharging = isCharging
        self.timestamp = timestamp
    }
}
