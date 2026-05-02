import SwiftUI
import USBMonitorCore

struct FilterBarView: View {
    @EnvironmentObject var filterEngine: FilterEngine

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(.secondary)
                .font(.caption)

            Text("Filter by class:")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(DeviceClass.allCases.filter { $0 != .unknown }, id: \.self) { cls in
                        Toggle(isOn: Binding(
                            get: { filterEngine.selectedClasses.contains(cls) },
                            set: { on in
                                if on { filterEngine.selectedClasses.insert(cls) }
                                else { filterEngine.selectedClasses.remove(cls) }
                            }
                        )) {
                            Label(cls.rawValue, systemImage: cls.systemImageName)
                        }
                        .toggleStyle(.button)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            if filterEngine.hasActiveFilters {
                Button("Clear") { filterEngine.clearAll() }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
}
