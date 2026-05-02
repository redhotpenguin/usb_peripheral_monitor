import Foundation
import Combine
import USBMonitorCore

public struct PowerSample: Identifiable, Sendable {
    public let id = UUID()
    public let timestamp: Date
    public let watts: Double
}

public final class InspectorController: ObservableObject {
    @Published public private(set) var powerSamples: [PowerSample] = []
    @Published public private(set) var currentPower: PowerSource? = nil

    private let maxSamples = 60
    private var cancellables = Set<AnyCancellable>()

    public init() {
        DeviceEventBus.shared.powerSourceUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] source in
                guard let self else { return }
                self.currentPower = source
                let sample = PowerSample(timestamp: Date(), watts: source.currentWatts)
                self.powerSamples.append(sample)
                if self.powerSamples.count > self.maxSamples {
                    self.powerSamples.removeFirst(self.powerSamples.count - self.maxSamples)
                }
            }
            .store(in: &cancellables)
    }
}
