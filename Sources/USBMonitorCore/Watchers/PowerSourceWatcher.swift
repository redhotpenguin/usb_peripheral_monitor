import Foundation
import IOKit.ps
import Combine

@MainActor
public final class PowerSourceWatcher: ObservableObject {
    @Published public private(set) var sources: [PowerSource] = []
    @Published public private(set) var currentSource: PowerSource?

    private var runLoopSource: CFRunLoopSource?

    public init() {}

    public func start() {
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        runLoopSource = IOPSNotificationCreateRunLoopSource(
            { ptr in
                guard let ptr else { return }
                let watcher = Unmanaged<PowerSourceWatcher>.fromOpaque(ptr).takeUnretainedValue()
                Task { @MainActor in watcher.refresh() }
            },
            selfPtr
        ).takeRetainedValue()

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }
        refresh()
    }

    public func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            runLoopSource = nil
        }
    }

    private func refresh() {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return }

        var updated: [PowerSource] = []
        for psRef in list {
            guard let desc = IOPSGetPowerSourceDescription(info, psRef)?.takeUnretainedValue() as? [String: Any]
            else { continue }

            let name = desc[kIOPSNameKey] as? String ?? "Power Source"
            let voltage = (desc["Voltage"] as? Double).map { $0 / 1000.0 } ?? 0
            let amperage = (desc["Amperage"] as? Double).map { $0 / 1000.0 } ?? 0
            let watts = voltage * abs(amperage)
            let maxWatts = (desc["MaxCapacity"] as? Double) ?? 0
            let isCharging = (desc[kIOPSIsChargingKey] as? Bool) ?? false

            updated.append(PowerSource(
                name: name,
                currentWatts: watts,
                voltageV: voltage,
                amperageA: amperage,
                maxWatts: maxWatts,
                isCharging: isCharging
            ))
        }

        sources = updated
        currentSource = updated.first
        updated.forEach { DeviceEventBus.shared.powerSourceUpdated.send($0) }
    }
}
