import Foundation
import IOKit
import Combine

@MainActor
public final class PDIdentityWatcher: ObservableObject {
    @Published public private(set) var identities: [PDIdentity] = []

    private var notifyPort: IONotificationPortRef?
    private var iterator: io_iterator_t = 0

    public init() {}

    public func start() {
        notifyPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let port = notifyPort else { return }

        let runLoopSource = IONotificationPortGetRunLoopSource(port).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

        let matchingDict = IOServiceMatching("IOUSBHostDevice") as NSMutableDictionary
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        IOServiceAddMatchingNotification(
            port,
            kIOFirstMatchNotification,
            matchingDict,
            { ptr, iter in
                guard let ptr else { return }
                let watcher = Unmanaged<PDIdentityWatcher>.fromOpaque(ptr).takeUnretainedValue()
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
            if let identity = extractPDIdentity(from: service) {
                identities.append(identity)
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iter)
        }
    }

    private func extractPDIdentity(from service: io_service_t) -> PDIdentity? {
        var propsRef: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let props = propsRef?.takeRetainedValue() as? [String: Any] else { return nil }

        // Only process USB-C devices with PD VDOs
        guard let vdoData = props["USB PD VDO"] as? [Int], !vdoData.isEmpty else { return nil }

        let vdos = vdoData.map { UInt32(bitPattern: Int32($0)) }
        return PDVDO.decode(vdos: vdos)
    }
}
