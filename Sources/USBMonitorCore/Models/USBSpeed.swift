import Foundation

public enum USBSpeed: String, Codable, CaseIterable, Comparable, Sendable {
    case lowSpeed = "Low Speed"
    case fullSpeed = "Full Speed"
    case highSpeed = "High Speed"
    case superSpeed = "SuperSpeed"
    case superSpeedPlus = "SuperSpeed+"
    case usb4Gen2 = "USB4 Gen 2"
    case usb4Gen3 = "USB4 Gen 3"
    case unknown = "Unknown"

    public var mbps: Double {
        switch self {
        case .lowSpeed: return 1.5
        case .fullSpeed: return 12
        case .highSpeed: return 480
        case .superSpeed: return 5_000
        case .superSpeedPlus: return 10_000
        case .usb4Gen2: return 20_000
        case .usb4Gen3: return 40_000
        case .unknown: return 0
        }
    }

    public var shortLabel: String {
        switch self {
        case .lowSpeed: return "LS"
        case .fullSpeed: return "FS"
        case .highSpeed: return "HS"
        case .superSpeed: return "SS"
        case .superSpeedPlus: return "SS+"
        case .usb4Gen2: return "USB4 20"
        case .usb4Gen3: return "USB4 40"
        case .unknown: return "?"
        }
    }

    private var sortOrder: Int {
        switch self {
        case .lowSpeed: return 0
        case .fullSpeed: return 1
        case .highSpeed: return 2
        case .superSpeed: return 3
        case .superSpeedPlus: return 4
        case .usb4Gen2: return 5
        case .usb4Gen3: return 6
        case .unknown: return -1
        }
    }

    public static func < (lhs: USBSpeed, rhs: USBSpeed) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    public init(ioKitSpeed: Int) {
        switch ioKitSpeed {
        case 1: self = .lowSpeed
        case 2: self = .fullSpeed
        case 3: self = .highSpeed
        case 4: self = .superSpeed
        case 5: self = .superSpeedPlus
        case 6: self = .usb4Gen2
        case 7: self = .usb4Gen3
        default: self = .unknown
        }
    }
}
