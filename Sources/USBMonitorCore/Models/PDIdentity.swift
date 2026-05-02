import Foundation

public enum CableType: String, Codable, Sendable {
    case passive = "Passive"
    case active = "Active"
    case optical = "Optical"
    case unknown = "Unknown"
}

public struct AltMode: Codable, Sendable {
    public let svid: UInt16
    public let name: String

    public static let displayPort = AltMode(svid: 0xFF01, name: "DisplayPort")
    public static let thunderbolt = AltMode(svid: 0x8087, name: "Thunderbolt")
}

public struct PDIdentity: Identifiable, Codable, Sendable {
    public let id: UUID
    public let cableType: CableType
    public let maxSpeed: USBSpeed
    public let maxPowerWatts: Double
    public let altModes: [AltMode]
    public let isCertified: Bool
    public let vendorID: UInt16
    public let productID: UInt16

    public var supportsDisplayPort: Bool {
        altModes.contains { $0.svid == AltMode.displayPort.svid }
    }

    public var supportsThunderbolt: Bool {
        altModes.contains { $0.svid == AltMode.thunderbolt.svid }
    }

    public init(
        id: UUID = UUID(),
        cableType: CableType = .unknown,
        maxSpeed: USBSpeed = .unknown,
        maxPowerWatts: Double = 0,
        altModes: [AltMode] = [],
        isCertified: Bool = false,
        vendorID: UInt16 = 0,
        productID: UInt16 = 0
    ) {
        self.id = id
        self.cableType = cableType
        self.maxSpeed = maxSpeed
        self.maxPowerWatts = maxPowerWatts
        self.altModes = altModes
        self.isCertified = isCertified
        self.vendorID = vendorID
        self.productID = productID
    }
}
