import Foundation
import IOKit
import IOKit.usb
import Combine

@MainActor
public final class USBDeviceWatcher: ObservableObject {
    @Published public private(set) var devices: [USBDevice] = []

    private var notifyPort: IONotificationPortRef?
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0
    private var deviceIDMap: [UInt32: UUID] = [:]  // locationID → device UUID

    public init() {}

    public func start() {
        notifyPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let port = notifyPort else { return }

        let runLoopSource = IONotificationPortGetRunLoopSource(port).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        IOServiceAddMatchingNotification(
            port,
            kIOFirstMatchNotification,
            matchingDict,
            { ptr, iterator in
                guard let ptr else { return }
                let watcher = Unmanaged<USBDeviceWatcher>.fromOpaque(ptr).takeUnretainedValue()
                Task { @MainActor in watcher.handleAttached(iterator: iterator) }
            },
            selfPtr,
            &addedIterator
        )

        IOServiceAddMatchingNotification(
            port,
            kIOTerminatedNotification,
            matchingDict,
            { ptr, iterator in
                guard let ptr else { return }
                let watcher = Unmanaged<USBDeviceWatcher>.fromOpaque(ptr).takeUnretainedValue()
                Task { @MainActor in watcher.handleDetached(iterator: iterator) }
            },
            selfPtr,
            &removedIterator
        )

        // drain initial iterators to arm notifications
        handleAttached(iterator: addedIterator)
        handleDetached(iterator: removedIterator)
    }

    public func stop() {
        if addedIterator != 0 { IOObjectRelease(addedIterator); addedIterator = 0 }
        if removedIterator != 0 { IOObjectRelease(removedIterator); removedIterator = 0 }
        if let port = notifyPort {
            IONotificationPortDestroy(port)
            notifyPort = nil
        }
    }

    private func handleAttached(iterator: io_iterator_t) {
        var service = IOIteratorNext(iterator)
        while service != 0 {
            if let device = makeDevice(from: service) {
                deviceIDMap[device.locationID] = device.id
                devices.removeAll { $0.locationID == device.locationID }
                devices.append(device)
                let event = DeviceEvent(deviceID: device.id, eventType: .attach, locationID: device.locationID)
                DeviceEventBus.shared.deviceAttached.send(device)
                DeviceEventBus.shared.deviceEvents.send(event)
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
    }

    private func handleDetached(iterator: io_iterator_t) {
        var service = IOIteratorNext(iterator)
        while service != 0 {
            let locationID = locationID(for: service)
            if let uuid = deviceIDMap[locationID],
               let device = devices.first(where: { $0.id == uuid }) {
                devices.removeAll { $0.id == uuid }
                deviceIDMap.removeValue(forKey: locationID)
                let event = DeviceEvent(deviceID: device.id, eventType: .detach, locationID: locationID)
                DeviceEventBus.shared.deviceDetached.send(device)
                DeviceEventBus.shared.deviceEvents.send(event)
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
    }

    private func makeDevice(from service: io_service_t) -> USBDevice? {
        var propsRef: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let props = propsRef?.takeRetainedValue() as? [String: Any] else { return nil }

        let vendorID = (props["idVendor"] as? Int).map(UInt16.init) ?? 0
        let productID = (props["idProduct"] as? Int).map(UInt16.init) ?? 0
        let locID = (props["locationID"] as? Int).map(UInt32.init) ?? locationID(for: service)
        let speedRaw = (props["Device Speed"] as? Int) ?? 0
        let speed = USBSpeed(ioKitSpeed: speedRaw)
        let serialNumber = props["USB Serial Number"] as? String
        let productName = props["USB Product Name"] as? String
        let vendorName = (props["USB Vendor Name"] as? String) ?? VendorDatabase.name(for: vendorID)
        let deviceClass = DeviceClassDecoder.decode(from: props)

        return USBDevice(
            vendorID: vendorID,
            productID: productID,
            vendorName: vendorName,
            productName: productName,
            deviceClass: deviceClass,
            speed: speed,
            serialNumber: serialNumber,
            locationID: locID
        )
    }

    private func locationID(for service: io_service_t) -> UInt32 {
        var locationID: UInt32 = 0
        if let val = IORegistryEntryCreateCFProperty(service, "locationID" as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? Int {
            locationID = UInt32(val)
        }
        return locationID
    }
}
