import Foundation

// USB Power Delivery Vendor Defined Objects (VDO) decoder.
// Bit-field layout follows USB PD spec rev 3.1.
public enum PDVDO {

    // MARK: - ID Header VDO (first VDO in Discover Identity response)

    public struct IDHeaderVDO {
        public let usbHostCapable: Bool
        public let usbDeviceCapable: Bool
        public let productType: ProductType
        public let vendorID: UInt16

        public enum ProductType: UInt8 {
            case undefined = 0
            case hub = 1
            case peripheral = 2
            case passiveCable = 3
            case activeCable = 4
            case ama = 5  // Alternate Mode Adapter
            case vpd = 6  // Vconn Powered Device
        }

        public init(raw: UInt32) {
            usbHostCapable = (raw >> 31) & 1 == 1
            usbDeviceCapable = (raw >> 30) & 1 == 1
            productType = ProductType(rawValue: UInt8((raw >> 27) & 0x7)) ?? .undefined
            vendorID = UInt16(raw & 0xFFFF)
        }
    }

    // MARK: - Cable VDO

    public struct CableVDO {
        public let usbSuperSpeedSupport: SpeedSupport
        public let activeCable: Bool
        public let opticalCable: Bool
        public let maxVBusCurrent: VBusCurrent
        public let maxVBusVoltage: VBusVoltage
        public let cableTerminationType: TerminationType

        public enum SpeedSupport: UInt8 {
            case usb2Only = 0
            case usb3Gen1 = 1
            case usb3Gen1Gen2 = 2
            case usb4Gen2 = 3
            case usb4Gen3 = 4
        }

        public enum VBusCurrent: UInt8 {
            case a3 = 0
            case a5 = 1
            case a5_active = 2
        }

        public enum VBusVoltage: UInt8 {
            case v20 = 0
            case v30 = 1
            case v40 = 2
            case v50 = 3
        }

        public enum TerminationType: UInt8 {
            case vconn1 = 0
            case vconn2 = 1
            case vconn3 = 2
            case vconn4 = 3
        }

        public init(raw: UInt32) {
            usbSuperSpeedSupport = SpeedSupport(rawValue: UInt8(raw & 0x7)) ?? .usb2Only
            activeCable = (raw >> 3) & 1 == 1
            opticalCable = (raw >> 4) & 1 == 1
            maxVBusCurrent = VBusCurrent(rawValue: UInt8((raw >> 5) & 0x3)) ?? .a3
            maxVBusVoltage = VBusVoltage(rawValue: UInt8((raw >> 9) & 0x3)) ?? .v20
            cableTerminationType = TerminationType(rawValue: UInt8((raw >> 18) & 0x3)) ?? .vconn1
        }

        public var usbSpeed: USBSpeed {
            switch usbSuperSpeedSupport {
            case .usb2Only: return .highSpeed
            case .usb3Gen1: return .superSpeed
            case .usb3Gen1Gen2: return .superSpeedPlus
            case .usb4Gen2: return .usb4Gen2
            case .usb4Gen3: return .usb4Gen3
            }
        }

        public var maxCurrentAmps: Double {
            switch maxVBusCurrent {
            case .a3: return 3.0
            case .a5, .a5_active: return 5.0
            }
        }

        public var maxVoltageVolts: Double {
            switch maxVBusVoltage {
            case .v20: return 20.0
            case .v30: return 30.0
            case .v40: return 40.0
            case .v50: return 50.0
            }
        }

        public var maxPowerWatts: Double {
            maxCurrentAmps * maxVoltageVolts
        }
    }

    // MARK: - Decode

    public static func decode(vdos: [UInt32]) -> PDIdentity? {
        guard vdos.count >= 3 else { return nil }

        let header = IDHeaderVDO(raw: vdos[0])
        let isActiveCable: Bool
        let maxSpeed: USBSpeed
        let maxPower: Double
        var cableType: CableType = .passive

        if vdos.count >= 4 {
            let cable = CableVDO(raw: vdos[3])
            isActiveCable = cable.activeCable
            maxSpeed = cable.usbSpeed
            maxPower = cable.maxPowerWatts
            cableType = cable.opticalCable ? .optical : (isActiveCable ? .active : .passive)
        } else {
            maxSpeed = .unknown
            maxPower = 0
        }

        return PDIdentity(
            cableType: cableType,
            maxSpeed: maxSpeed,
            maxPowerWatts: maxPower,
            isCertified: header.usbDeviceCapable,
            vendorID: header.vendorID
        )
    }
}
