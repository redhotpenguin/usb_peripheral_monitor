import SwiftUI
import Combine
import USBMonitorCore

@main
struct USBMonitorDesktopApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState.deviceWatcher)
                .environmentObject(appState.powerWatcher)
                .environmentObject(appState.usbcWatcher)
                .environmentObject(appState.eventHistory)
                .environmentObject(appState.filterEngine)
                .environmentObject(appState.sidebarController)
                .environmentObject(appState.detailController)
                .environmentObject(appState.inspectorController)
                .onAppear { appState.start() }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            PreferencesView()
        }
    }
}

// Single container object owns all watchers and wires their subscriptions.
@MainActor
final class AppState: ObservableObject {
    let deviceWatcher = USBDeviceWatcher()
    let powerWatcher = PowerSourceWatcher()
    let usbcWatcher = USBCPortWatcher()
    let eventHistory = EventHistory()
    let filterEngine = FilterEngine()
    let database = DatabaseManager()
    let inspectorController = InspectorController()
    let detailController: DetailController
    let sidebarController: SidebarController

    private var cancellables = Set<AnyCancellable>()

    init() {
        detailController = DetailController(database: database)
        sidebarController = SidebarController(database: database, eventHistory: eventHistory, filterEngine: filterEngine)

        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dir = appSupport.appendingPathComponent("USBMonitor", isDirectory: true)
            let dbURL = dir.appendingPathComponent("events.db")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try? database.open(at: dbURL)
        }
    }

    func start() {
        deviceWatcher.start()
        powerWatcher.start()
        usbcWatcher.start()
        subscribeToBus()
        // Initial devices were emitted before the bus subscription was wired;
        // force a refresh so displayDevices (and smart group filters) are populated.
        sidebarController.refresh(devices: deviceWatcher.devices)
    }

    private func subscribeToBus() {
        let bus = DeviceEventBus.shared

        bus.deviceAttached
            .receive(on: DispatchQueue.main)
            .sink { [weak self] device in
                guard let self else { return }
                database.persist(device: device)
                let event = DeviceEvent(deviceID: device.id, eventType: .attach, locationID: device.locationID)
                database.persist(event: event)
                eventHistory.append(event)
                detailController.appendLiveEvent(event)
                sidebarController.refresh(devices: deviceWatcher.devices)
            }
            .store(in: &cancellables)

        bus.deviceDetached
            .receive(on: DispatchQueue.main)
            .sink { [weak self] device in
                guard let self else { return }
                let event = DeviceEvent(deviceID: device.id, eventType: .detach, locationID: device.locationID)
                database.persist(event: event)
                eventHistory.append(event)
                detailController.appendLiveEvent(event)
                sidebarController.refresh(devices: deviceWatcher.devices)
            }
            .store(in: &cancellables)
    }
}
