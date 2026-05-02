import SwiftUI
import USBMonitorCore

struct ContentView: View {
    @EnvironmentObject var deviceWatcher: USBDeviceWatcher
    @EnvironmentObject var sidebarController: SidebarController
    @EnvironmentObject var filterEngine: FilterEngine

    @State private var selection: SidebarSelection?
    @State private var showInspector = true
    @State private var showFilterBar = false
    @State private var searchText = ""
    @State private var lastUpdateDate = Date()

    private var selectedDevice: USBDevice? {
        guard case .device(let id) = selection else { return nil }
        return deviceWatcher.devices.first { $0.id == id }
    }

    private var groupDevices: [USBDevice]? {
        switch selection {
        case .allDevices:         return deviceWatcher.devices
        case .recentlyConnected:  return sidebarController.recentlyConnected
        case .highSpeed:          return sidebarController.highSpeedDevices
        default:                  return nil
        }
    }

    private var groupTitle: String {
        switch selection {
        case .allDevices:         return "All Devices"
        case .recentlyConnected:  return "Recently Connected"
        case .highSpeed:          return "High-Speed Devices"
        default:                  return ""
        }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } detail: {
            HSplitView {
                Group {
                    if let devices = groupDevices {
                        GroupDetailView(title: groupTitle, devices: devices)
                    } else {
                        DetailView(device: selectedDevice)
                    }
                }
                .frame(minWidth: 400)

                if showInspector {
                    InspectorView(device: selectedDevice)
                        .frame(minWidth: 250, idealWidth: 280, maxWidth: 350)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { sidebarController.refresh(devices: deviceWatcher.devices) }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }

                ExportMenuButton(devices: deviceWatcher.devices)

                Toggle(isOn: $showFilterBar) {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
                .toggleStyle(.button)

                Button(action: { showInspector.toggle() }) {
                    Label("Inspector", systemImage: "sidebar.right")
                }
                .help(showInspector ? "Hide Inspector" : "Show Inspector")
            }

            ToolbarItem(placement: .automatic) {
                SearchField(text: $searchText)
                    .frame(width: 220)
                    .onChange(of: searchText) { new in
                        filterEngine.searchText = new
                    }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if showFilterBar {
                FilterBarView()
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(.regularMaterial)
            }
        }
        .overlay(alignment: .bottom) {
            StatusBarView(deviceCount: deviceWatcher.devices.count, lastUpdate: lastUpdateDate)
        }
        .onReceive(deviceWatcher.$devices) { _ in
            lastUpdateDate = Date()
        }
    }
}
