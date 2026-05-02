import Foundation
import IOKit
import Combine

@MainActor
public final class USBCPortWatcher: ObservableObject {
    @Published public private(set) var ports: [USBCPort] = []

    private var notifyPort: IONotificationPortRef?
    private var iterator: io_iterator_t = 0

    public init() {}

    public func start() {
        notifyPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let port = notifyPort else { return }

        let runLoopSource = IONotificationPortGetRunLoopSource(port).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

        // Match USB Type C Port Controller
        let matchingDict = IOServiceMatching("IOUSBTypeCPortController") as NSMutableDictionary
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        IOServiceAddMatchingNotification(
            port,
            kIOFirstMatchNotification,
            matchingDict,
            { ptr, iter in
                guard let ptr else { return }
                let watcher = Unmanaged<USBCPortWatcher>.fromOpaque(ptr).takeUnretainedValue()
                Task { @MainActor in watcher.handleIterator(iter) }
            },
            selfPtr,
            &iterator
        )
        handleIterator(iterator)
    }

    public func stop() {
        if iterator != 0 { IOObjectRelease(iterator); iterator = 0 }
        if let port = notifyPort { IONotificationPortDestroy(port); notifyPort = nil }
    }

    private func handleIterator(_ iter: io_iterator_t) {
        var service = IOIteratorNext(iter)
        while service != 0 {
            if let port = makePort(from: service) {
                ports.removeAll { $0.locationID == port.locationID }
                ports.append(port)
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iter)
        }
    }

    private func makePort(from service: io_service_t) -> USBCPort? {
        var propsRef: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let props = propsRef?.takeRetainedValue() as? [String: Any] else { return nil }

        let locID = (props["locationID"] as? Int).map(UInt32.init) ?? 0
        let portNum = (props["PortNumber"] as? Int) ?? 0
        let speedRaw = (props["Device Speed"] as? Int) ?? 0

        return USBCPort(
            locationID: locID,
            portNumber: portNum,
            isConnected: true,
            currentSpeed: USBSpeed(ioKitSpeed: speedRaw)
        )
    }
}
