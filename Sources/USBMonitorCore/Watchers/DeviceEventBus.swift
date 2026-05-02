import Foundation
import Combine

public final class DeviceEventBus: @unchecked Sendable {
    public static let shared = DeviceEventBus()

    public let deviceEvents = PassthroughSubject<DeviceEvent, Never>()
    public let deviceAttached = PassthroughSubject<USBDevice, Never>()
    public let deviceDetached = PassthroughSubject<USBDevice, Never>()
    public let powerSourceUpdated = PassthroughSubject<PowerSource, Never>()

    private init() {}
}
