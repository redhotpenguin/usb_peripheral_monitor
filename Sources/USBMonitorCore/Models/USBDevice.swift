import Foundation

public struct USBDevice: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let vendorID: UInt16
    public let productID: UInt16
    public let vendorName: String?
    public let productName: String?
    public let deviceClass: DeviceClass
    public let speed: USBSpeed
    public let serialNumber: String?
    public let locationID: UInt32
    public let connectedAt: Date
    public let parentHub: UUID?

    public var displayName: String {
        if let name = productName, !name.isEmpty { return name }
        if let vendor = vendorName, !vendor.isEmpty {
            return "\(vendor) Device"
        }
        return String(format: "USB Device %04X:%04X", vendorID, productID)
    }

    public var vendorIDHex: String { String(format: "0x%04X", vendorID) }
    public var productIDHex: String { String(format: "0x%04X", productID) }
    public var locationIDHex: String { String(format: "0x%08X", locationID) }

    public init(
        id: UUID = UUID(),
        vendorID: UInt16,
        productID: UInt16,
        vendorName: String? = nil,
        productName: String? = nil,
        deviceClass: DeviceClass = .unknown,
        speed: USBSpeed = .unknown,
        serialNumber: String? = nil,
        locationID: UInt32,
        connectedAt: Date = Date(),
        parentHub: UUID? = nil
    ) {
        self.id = id
        self.vendorID = vendorID
        self.productID = productID
        self.vendorName = vendorName
        self.productName = productName
        self.deviceClass = deviceClass
        self.speed = speed
        self.serialNumber = serialNumber
        self.locationID = locationID
        self.connectedAt = connectedAt
        self.parentHub = parentHub
    }

    public static func == (lhs: USBDevice, rhs: USBDevice) -> Bool {
        lhs.id == rhs.id
    }
}
