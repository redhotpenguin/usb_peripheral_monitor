import Foundation
import Combine
import USBMonitorCore

public final class FilterEngine: ObservableObject {
    @Published public var searchText: String = ""
    @Published public var selectedClasses: Set<DeviceClass> = []
    @Published public var minSpeed: USBSpeed? = nil
    @Published public var onlyHighPower: Bool = false

    @Published public private(set) var filteredDevices: [USBDevice] = []

    private var allDevices: [USBDevice] = []
    private var cancellables = Set<AnyCancellable>()

    public init() {
        Publishers.CombineLatest4($searchText, $selectedClasses, $minSpeed, $onlyHighPower)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _, _ in
                self?.refilter()
            }
            .store(in: &cancellables)
    }

    public func apply(to devices: [USBDevice]) {
        allDevices = devices
        refilter()
    }

    private func refilter() {
        var result = allDevices

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.displayName.lowercased().contains(q)
                || ($0.vendorName?.lowercased().contains(q) == true)
                || $0.vendorIDHex.lowercased().contains(q)
                || $0.productIDHex.lowercased().contains(q)
            }
        }

        if !selectedClasses.isEmpty {
            result = result.filter { selectedClasses.contains($0.deviceClass) }
        }

        if let minSpeed {
            result = result.filter { $0.speed >= minSpeed }
        }

        filteredDevices = result
    }

    public var hasActiveFilters: Bool {
        !searchText.isEmpty || !selectedClasses.isEmpty || minSpeed != nil || onlyHighPower
    }

    public func clearAll() {
        searchText = ""
        selectedClasses = []
        minSpeed = nil
        onlyHighPower = false
    }
}
