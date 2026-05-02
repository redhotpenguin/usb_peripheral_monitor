import Foundation
import Combine

public final class EventHistory: ObservableObject, @unchecked Sendable {
    @Published public private(set) var events: [DeviceEvent] = []
    private let maxInMemory: Int

    public init(maxInMemory: Int = 500) {
        self.maxInMemory = maxInMemory
    }

    public func append(_ event: DeviceEvent) {
        events.append(event)
        if events.count > maxInMemory {
            events.removeFirst(events.count - maxInMemory)
        }
    }

    public func events(for deviceID: UUID) -> [DeviceEvent] {
        events.filter { $0.deviceID == deviceID }
    }

    public func recentEvents(since date: Date) -> [DeviceEvent] {
        events.filter { $0.timestamp >= date }
    }
}
