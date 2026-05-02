import Foundation

public enum VendorDatabase {
    public static func name(for vendorID: UInt16) -> String? {
        vendors[vendorID]
    }

    // Subset of USB.org vendor IDs — most common brands
    private static let vendors: [UInt16: String] = [
        0x0403: "FTDI",
        0x0409: "NEC",
        0x045E: "Microsoft",
        0x046D: "Logitech",
        0x0480: "Toshiba",
        0x04B3: "IBM",
        0x04D9: "Holtek Semiconductor",
        0x04E8: "Samsung",
        0x04F2: "Chicony Electronics",
        0x050D: "Belkin",
        0x0557: "ATEN International",
        0x05AC: "Apple",
        0x05DC: "Lexar",
        0x05E3: "Genesys Logic",
        0x067B: "Prolific Technology",
        0x06CB: "Synaptics",
        0x0781: "SanDisk",
        0x0930: "Toshiba",
        0x0951: "Kingston Technology",
        0x09DA: "A4tech",
        0x0A5C: "Broadcom",
        0x0B05: "ASUSTeK Computer",
        0x0B95: "ASIX Electronics",
        0x0BDA: "Realtek Semiconductor",
        0x0CF3: "Qualcomm Atheros",
        0x0D8C: "C-Media Electronics",
        0x0E0F: "VMware",
        0x0F0D: "Hori",
        0x1017: "Speeze Dazen",
        0x1050: "Yubico",
        0x13FE: "Phison Electronics",
        0x1532: "Razer USA",
        0x154B: "PNY Technologies",
        0x1A86: "QinHeng Electronics",
        0x1D50: "OpenMoko",
        0x2109: "VIA Labs",
        0x2188: "CalDigit",
        0x2357: "TP-Link",
        0x239A: "Adafruit Industries",
        0x258A: "SINOWEALTH",
        0x27C6: "Shenzhen Goodix Technology",
        0x2A2B: "Plugable Technologies",
        0x2C7C: "Quectel Wireless Solutions",
        0x303A: "Espressif Systems",
        0x8087: "Intel",
        0xCB10: "Targus",
    ]
}
