import Foundation
import SQLite

public final class DatabaseManager: @unchecked Sendable {
    private var db: Connection?
    private let queue = DispatchQueue(label: "com.usbmonitor.database", qos: .utility)

    // Tables
    private let devicesTable = Table("devices")
    private let eventsTable = Table("events")

    // Device columns
    private let colID = Expression<String>("id")
    private let colVendorID = Expression<Int>("vendor_id")
    private let colProductID = Expression<Int>("product_id")
    private let colVendorName = Expression<String?>("vendor_name")
    private let colProductName = Expression<String?>("product_name")
    private let colDeviceClass = Expression<String>("device_class")
    private let colSpeed = Expression<String>("speed")
    private let colSerialNumber = Expression<String?>("serial_number")

    // Event columns
    private let colEventID = Expression<Int64>("id")
    private let colDeviceIDFK = Expression<String>("device_id")
    private let colEventType = Expression<String>("event_type")
    private let colTimestamp = Expression<Date>("timestamp")
    private let colLocationID = Expression<Int64>("location_id")
    private let colProperties = Expression<String?>("properties")

    public init() {}

    public func open(at url: URL) throws {
        let connection = try Connection(url.path)
        try createTablesIfNeeded(connection)
        db = connection
    }

    private func createTablesIfNeeded(_ db: Connection) throws {
        try db.run(devicesTable.create(ifNotExists: true) { t in
            t.column(colID, primaryKey: true)
            t.column(colVendorID)
            t.column(colProductID)
            t.column(colVendorName)
            t.column(colProductName)
            t.column(colDeviceClass)
            t.column(colSpeed)
            t.column(colSerialNumber)
        })

        try db.run(eventsTable.create(ifNotExists: true) { t in
            t.column(colEventID, primaryKey: .autoincrement)
            t.column(colDeviceIDFK)
            t.column(colEventType)
            t.column(colTimestamp)
            t.column(colLocationID)
            t.column(colProperties)
            t.foreignKey(colDeviceIDFK, references: devicesTable, colID)
        })

        try db.run("CREATE INDEX IF NOT EXISTS idx_events_timestamp ON events(timestamp)")
        try db.run("CREATE INDEX IF NOT EXISTS idx_events_device ON events(device_id)")
    }

    public func persist(device: USBDevice) {
        guard let db else { return }
        queue.async {
            try? db.run(self.devicesTable.insert(or: .replace,
                self.colID <- device.id.uuidString,
                self.colVendorID <- Int(device.vendorID),
                self.colProductID <- Int(device.productID),
                self.colVendorName <- device.vendorName,
                self.colProductName <- device.productName,
                self.colDeviceClass <- device.deviceClass.rawValue,
                self.colSpeed <- device.speed.rawValue,
                self.colSerialNumber <- device.serialNumber
            ))
        }
    }

    public func persist(event: DeviceEvent) {
        guard let db else { return }
        queue.async {
            try? db.run(self.eventsTable.insert(
                self.colDeviceIDFK <- event.deviceID.uuidString,
                self.colEventType <- event.eventType.rawValue,
                self.colTimestamp <- event.timestamp,
                self.colLocationID <- Int64(event.locationID)
            ))
        }
    }

    public func queryAllDevices() -> [USBDevice] {
        guard let db else { return [] }
        var result: [USBDevice] = []
        queue.sync {
            let rows = (try? db.prepare(self.devicesTable)) ?? AnySequence([])
            for row in rows {
                guard let uuid = UUID(uuidString: row[self.colID]) else { continue }
                let device = USBDevice(
                    id: uuid,
                    vendorID: UInt16(row[self.colVendorID]),
                    productID: UInt16(row[self.colProductID]),
                    vendorName: row[self.colVendorName],
                    productName: row[self.colProductName],
                    deviceClass: DeviceClass(rawValue: row[self.colDeviceClass]) ?? .unknown,
                    speed: USBSpeed(rawValue: row[self.colSpeed]) ?? .unknown,
                    serialNumber: row[self.colSerialNumber],
                    locationID: 0
                )
                result.append(device)
            }
        }
        return result
    }

    public func queryEvents(for deviceID: UUID, limit: Int = 100) -> [DeviceEvent] {
        guard let db else { return [] }
        var result: [DeviceEvent] = []
        queue.sync {
            let query = self.eventsTable
                .filter(self.colDeviceIDFK == deviceID.uuidString)
                .order(self.colTimestamp.desc)
                .limit(limit)
            let rows = (try? db.prepare(query)) ?? AnySequence([])
            for row in rows {
                let event = DeviceEvent(
                    deviceID: deviceID,
                    eventType: EventType(rawValue: row[self.colEventType]) ?? .attach,
                    timestamp: row[self.colTimestamp],
                    locationID: UInt32(row[self.colLocationID])
                )
                result.append(event)
            }
        }
        return result.reversed()
    }

    public func queryRecentEvents(since date: Date) -> [DeviceEvent] {
        guard let db else { return [] }
        var result: [DeviceEvent] = []
        queue.sync {
            let query = self.eventsTable
                .filter(self.colTimestamp >= date)
                .order(self.colTimestamp.desc)
            let rows = (try? db.prepare(query)) ?? AnySequence([])
            for row in rows {
                guard let uuid = UUID(uuidString: row[self.colDeviceIDFK]) else { continue }
                let event = DeviceEvent(
                    deviceID: uuid,
                    eventType: EventType(rawValue: row[self.colEventType]) ?? .attach,
                    timestamp: row[self.colTimestamp],
                    locationID: UInt32(row[self.colLocationID])
                )
                result.append(event)
            }
        }
        return result
    }

    public func deleteEvents(olderThan date: Date) {
        guard let db else { return }
        queue.async {
            try? db.run(self.eventsTable.filter(self.colTimestamp < date).delete())
        }
    }
}
