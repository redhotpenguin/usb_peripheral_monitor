import Foundation
import Combine
import USBMonitorCore

public final class DetailController: ObservableObject {
    @Published public private(set) var events: [DeviceEvent] = []
    @Published public private(set) var pdIdentity: PDIdentity? = nil

    private let database: DatabaseManager
    private var cancellables = Set<AnyCancellable>()
    private var currentDeviceID: UUID?

    public init(database: DatabaseManager) {
        self.database = database
    }

    public func load(for device: USBDevice?) {
        guard let device, device.id != currentDeviceID else { return }
        currentDeviceID = device.id
        let deviceID = device.id

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let loaded = self.database.queryEvents(for: deviceID, limit: 200)
            DispatchQueue.main.async {
                self.events = loaded
            }
        }
    }

    public func appendLiveEvent(_ event: DeviceEvent) {
        guard event.deviceID == currentDeviceID else { return }
        events.append(event)
    }
}
