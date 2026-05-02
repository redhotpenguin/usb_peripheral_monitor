import Foundation

public enum DeviceClassDecoder {
    public static func decode(from props: [String: Any]) -> DeviceClass {
        let usbClass = (props["bDeviceClass"] as? Int).map(UInt8.init) ?? 0
        let subClass = (props["bDeviceSubClass"] as? Int).map(UInt8.init) ?? 0
        let proto = (props["bDeviceProtocol"] as? Int).map(UInt8.init) ?? 0

        // USB-C devices often expose a port controller class
        if props["IOUSBTypeCPortController"] != nil {
            return .usbC
        }

        if usbClass == 0 {
            // Check interface class from first interface descriptor
            if let interfaceClass = (props["bInterfaceClass"] as? Int).map(UInt8.init) {
                return DeviceClass(usbClass: interfaceClass, subClass: subClass, protocol: proto)
            }
        }

        return DeviceClass(usbClass: usbClass, subClass: subClass, protocol: proto)
    }

    public static func humanLabel(for deviceClass: DeviceClass) -> String {
        deviceClass.rawValue
    }
}
