import Foundation
import USBMonitorCore

enum SidebarSelection: Hashable {
    case allDevices
    case recentlyConnected
    case speed(USBSpeed)
    case device(UUID)
}
