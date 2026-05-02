import Foundation

enum SidebarSelection: Hashable {
    case allDevices
    case recentlyConnected
    case highSpeed
    case device(UUID)
}
