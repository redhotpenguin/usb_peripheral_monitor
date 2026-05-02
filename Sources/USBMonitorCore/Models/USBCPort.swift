import Foundation

public struct USBCPort: Identifiable, Codable, Sendable {
    public let id: UUID
    public let locationID: UInt32
    public let portNumber: Int
    public let isConnected: Bool
    public let currentSpeed: USBSpeed
    public let supportsAltMode: Bool
    public let supportsDisplayPort: Bool
    public let supportsThunderbolt: Bool
    public let maxPowerWatts: Double

    public var displayName: String { "USB-C Port \(portNumber)" }

    public init(
        id: UUID = UUID(),
        locationID: UInt32,
        portNumber: Int,
        isConnected: Bool = false,
        currentSpeed: USBSpeed = .unknown,
        supportsAltMode: Bool = false,
        supportsDisplayPort: Bool = false,
        supportsThunderbolt: Bool = false,
        maxPowerWatts: Double = 0
    ) {
        self.id = id
        self.locationID = locationID
        self.portNumber = portNumber
        self.isConnected = isConnected
        self.currentSpeed = currentSpeed
        self.supportsAltMode = supportsAltMode
        self.supportsDisplayPort = supportsDisplayPort
        self.supportsThunderbolt = supportsThunderbolt
        self.maxPowerWatts = maxPowerWatts
    }
}
