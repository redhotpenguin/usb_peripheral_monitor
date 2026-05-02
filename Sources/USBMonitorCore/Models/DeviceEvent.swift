import Foundation

public enum EventType: String, Codable, Sendable {
    case attach = "attach"
    case detach = "detach"

    public var label: String {
        switch self {
        case .attach: return "Connected"
        case .detach: return "Disconnected"
        }
    }

    public var systemImageName: String {
        switch self {
        case .attach: return "arrow.down.circle.fill"
        case .detach: return "arrow.up.circle"
        }
    }
}

public struct DeviceEvent: Identifiable, Codable, Sendable {
    public let id: UUID
    public let deviceID: UUID
    public let eventType: EventType
    public let timestamp: Date
    public let locationID: UInt32

    public init(
        id: UUID = UUID(),
        deviceID: UUID,
        eventType: EventType,
        timestamp: Date = Date(),
        locationID: UInt32
    ) {
        self.id = id
        self.deviceID = deviceID
        self.eventType = eventType
        self.timestamp = timestamp
        self.locationID = locationID
    }
}
