import Foundation

public struct DeviceNode: Identifiable {
    public let id: UUID
    public let device: USBDevice
    public var children: [DeviceNode]

    public init(device: USBDevice, children: [DeviceNode] = []) {
        self.id = device.id
        self.device = device
        self.children = children
    }
}

public enum TopologyAnalyzer {
    /// Builds a tree from a flat device list using parentHub relationships.
    public static func buildTree(from devices: [USBDevice]) -> [DeviceNode] {
        var nodeMap: [UUID: DeviceNode] = [:]
        for d in devices { nodeMap[d.id] = DeviceNode(device: d) }

        var roots: [DeviceNode] = []
        for d in devices {
            guard let child = nodeMap[d.id] else { continue }
            if let parentID = d.parentHub, nodeMap[parentID] != nil {
                nodeMap[parentID]?.children.append(child)
            } else {
                roots.append(child)
            }
        }
        return roots
    }

    /// Returns the depth of a device in the USB topology (root hubs are depth 0).
    public static func depth(of deviceID: UUID, in devices: [USBDevice]) -> Int {
        var depth = 0
        var current = devices.first { $0.id == deviceID }
        while let c = current, let parentID = c.parentHub {
            depth += 1
            current = devices.first { $0.id == parentID }
        }
        return depth
    }

    /// Returns immediate children of a device.
    public static func children(of parentID: UUID, in devices: [USBDevice]) -> [USBDevice] {
        devices.filter { $0.parentHub == parentID }
    }

    /// Returns all ancestors of a device, starting with the immediate parent.
    public static func ancestors(of deviceID: UUID, in devices: [USBDevice]) -> [USBDevice] {
        var ancestors: [USBDevice] = []
        var current = devices.first { $0.id == deviceID }
        while let c = current, let parentID = c.parentHub {
            if let parent = devices.first(where: { $0.id == parentID }) {
                ancestors.append(parent)
                current = parent
            } else {
                break
            }
        }
        return ancestors
    }
}
