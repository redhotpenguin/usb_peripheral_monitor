import Foundation

public struct BandwidthAllocation: Sendable {
    public let device: USBDevice
    public let theoreticalMbps: Double
    public let hubID: UUID?
}

public enum BandwidthAnalyzer {
    public static func theoreticalBandwidth(for device: USBDevice) -> Double {
        device.speed.mbps
    }

    /// Returns bandwidth allocation for all devices, grouped under hub IDs.
    public static func allocations(for devices: [USBDevice]) -> [BandwidthAllocation] {
        devices.map { BandwidthAllocation(device: $0, theoreticalMbps: $0.speed.mbps, hubID: $0.parentHub) }
    }

    /// Returns total theoretical bandwidth consumed under a given hub.
    public static func totalBandwidth(underHub hubID: UUID, in devices: [USBDevice]) -> Double {
        devices
            .filter { $0.parentHub == hubID }
            .reduce(0) { $0 + $1.speed.mbps }
    }

    /// Returns the highest-speed device in the set.
    public static func fastestDevice(in devices: [USBDevice]) -> USBDevice? {
        devices.max(by: { $0.speed < $1.speed })
    }
}
