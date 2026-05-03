import Foundation
import Combine
import USBMonitorCore

public final class SidebarController: ObservableObject {
    @Published public private(set) var displayDevices: [USBDevice] = []
    @Published public private(set) var sections: [DeviceSection] = []

    public let database: DatabaseManager
    public let eventHistory: EventHistory
    private let filterEngineRef: FilterEngine
    private var cancellables = Set<AnyCancellable>()

    public struct DeviceSection: Identifiable {
        public let id: DeviceClass
        public let title: String
        public let devices: [USBDevice]
        public var iconName: String { id.systemImageName }
    }

    public init(database: DatabaseManager, eventHistory: EventHistory, filterEngine: FilterEngine) {
        self.database = database
        self.eventHistory = eventHistory
        self.filterEngineRef = filterEngine

        filterEngine.$filteredDevices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                self?.displayDevices = devices
                self?.buildSections(from: devices)
            }
            .store(in: &cancellables)
    }

    public func refresh(devices: [USBDevice]) {
        filterEngineRef.apply(to: devices)
    }

    private func buildSections(from devices: [USBDevice]) {
        var grouped: [DeviceClass: [USBDevice]] = [:]
        for d in devices { grouped[d.deviceClass, default: []].append(d) }
        sections = DeviceClass.allCases.compactMap { cls in
            guard let devs = grouped[cls], !devs.isEmpty else { return nil }
            return DeviceSection(id: cls, title: cls.rawValue, devices: devs)
        }
    }

    public var recentlyConnected: [USBDevice] {
        let cutoff = Date().addingTimeInterval(-3600)
        return displayDevices.filter { $0.connectedAt >= cutoff }
    }

    public func devices(at speed: USBSpeed) -> [USBDevice] {
        displayDevices.filter { $0.speed == speed }
    }
}
