import Foundation

public enum DeviceClass: String, Codable, CaseIterable, Sendable {
    case hub = "Hub"
    case storage = "Storage"
    case hid = "HID"
    case audio = "Audio"
    case video = "Video"
    case communications = "Communications"
    case printer = "Printer"
    case smartCard = "Smart Card"
    case wirelessController = "Wireless"
    case usbC = "USB-C"
    case vendor = "Vendor Specific"
    case unknown = "Unknown"

    public var systemImageName: String {
        switch self {
        case .hub: return "arrow.triangle.branch"
        case .storage: return "externaldrive"
        case .hid: return "keyboard"
        case .audio: return "headphones"
        case .video: return "camera"
        case .communications: return "network"
        case .printer: return "printer"
        case .smartCard: return "creditcard"
        case .wirelessController: return "antenna.radiowaves.left.and.right"
        case .usbC: return "cable.connector"
        case .vendor: return "cpu"
        case .unknown: return "questionmark.circle"
        }
    }

    public init(usbClass: UInt8, subClass: UInt8, protocol proto: UInt8) {
        switch usbClass {
        case 0x01: self = .audio
        case 0x02, 0x0A: self = .communications
        case 0x03: self = .hid
        case 0x06: self = .storage
        case 0x07: self = .printer
        case 0x08: self = .storage
        case 0x09: self = .hub
        case 0x0B: self = .smartCard
        case 0x0E: self = .video
        case 0xE0: self = .wirelessController
        case 0xFF: self = .vendor
        default: self = .unknown
        }
    }
}
