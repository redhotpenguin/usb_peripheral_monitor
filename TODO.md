# USB Peripheral Monitor — Desktop App TODO

## Phase 1: Project Scaffolding
- [x] Create `Package.swift` — 2 targets (USBMonitorCore lib, USBMonitorDesktop exe), SQLite.swift dep
- [x] Create all source directories under `Sources/USBMonitorCore/{Watchers,Models,Decoders,Database,Export,Analytics}/`
- [x] Create `Sources/USBMonitorDesktop/{Controllers,Views,Windows}/`
- [x] Create `Resources/Assets.xcassets`
- [x] Create `Resources/Database/schema.sql`
- [ ] Add `USBMonitorDesktop.entitlements` with IOKit temporary exception entitlement
- [x] Verify `swift build` resolves dependencies cleanly

## Phase 2: Core Data Models (`USBMonitorCore/Models/`)
- [x] `DeviceClass.swift` — enum: Hub, Storage, HID, Audio, Video, Vendor, Unknown
- [x] `USBSpeed.swift` — enum: LowSpeed, FullSpeed, HighSpeed, SuperSpeed, SuperSpeedPlus, USB4
- [x] `USBDevice.swift` — Identifiable + Codable struct (vendorID, productID, names, class, speed, serialNumber, locationID, connectedAt, parentHub, rawProperties)
- [x] `USBCPort.swift` — struct for USB-C port controller state
- [x] `PowerSource.swift` — struct: current watts, voltage, amperage, maxWatts, description
- [x] `PDIdentity.swift` — struct: cableType, maxSpeed, maxPower, altModes, certificationStatus
- [x] `DeviceEvent.swift` — struct: id, deviceID, eventType (attach/detach), timestamp, locationID, properties
- [x] `EventHistory.swift` — ObservableObject wrapping array of DeviceEvent + capped in-memory store

## Phase 3: IOKit Watchers (`USBMonitorCore/Watchers/`)
- [x] `DeviceEventBus.swift` — shared Combine PassthroughSubject<DeviceEvent, Never>
- [x] `USBDeviceWatcher.swift` — @MainActor ObservableObject; IOKit matching for IOUSBHostDevice; publish USBDevice on attach/detach; emit to DeviceEventBus
- [x] `USBCPortWatcher.swift` — monitor USB-C port controllers; emit USBCPort updates
- [x] `PowerSourceWatcher.swift` — IOPSCopyPowerSourcesInfo + IOPSNotificationCreateRunLoopSource; emit PowerSource updates
- [x] `PDIdentityWatcher.swift` — read USB PD VDO data from IOKit; emit PDIdentity

## Phase 4: USB-C / PD Decoders (`USBMonitorCore/Decoders/`)
- [x] `PDVDO.swift` — VDO bit-field structs: IDHeaderVDO, CertStatVDO, ProductVDO, CableVDO (port from WhatCable patterns)
- [x] `PDOParser.swift` — parse PDO list bytes → PowerDeliveryProfile (voltage, current, type)
- [x] `DeviceClassDecoder.swift` — map (bDeviceClass, bDeviceSubClass, bDeviceProtocol) → DeviceClass + human label
- [x] `VendorDatabase.swift` — static [UInt16: String] lookup table of major USB vendor IDs

## Phase 5: Database Layer (`USBMonitorCore/Database/`)
- [x] `schema.sql` — devices + events tables with indexes
- [x] `DatabaseManager.swift` — SQLite.swift wrapper: open(url:), persistDevice(_:), persistEvent(_:), queryEvents(for:limit:), queryAllDevices(), queryRecentEvents(since:)

## Phase 6: Export & Analytics
- [x] `ExportManager.swift` — exportCSV(devices:) → Data, exportJSON(devices:events:) → Data, exportPDF(devices:events:) → Data, exportHTML(devices:events:) → Data
- [x] `ReportGenerator.swift` — formatted device-inventory summary with section headers
- [x] `TopologyAnalyzer.swift` — build parent-child tree from locationID bitmask; `children(of:in:)` helper
- [x] `BandwidthAnalyzer.swift` — theoretical speed per USBSpeed; aggregate bandwidth per hub

## Phase 7: Desktop App Entry & Window
- [x] `App.swift` — @main SwiftUI App; WindowGroup with ContentView; min size 900×600, default 1200×800; unified toolbar style; inject environment objects (watchers, DatabaseManager, FilterEngine)
- [x] `ContentView.swift` — NavigationSplitView(sidebar: SidebarView, detail: DetailView, Inspector: InspectorView); toolbar items; search binding

## Phase 8: Sidebar
- [x] `SidebarView.swift` — List with sections per DeviceClass; smart groups (Recently Connected, Disconnected Today, High-Speed); "All Devices (N)" row; drives selectedDevice binding
- [ ] `DeviceTreeView.swift` — recursive DisclosureGroup showing hub → child device hierarchy from TopologyAnalyzer
- [x] `SidebarController.swift` — ObservableObject; owns filtered device list; subscribes to DeviceEventBus; applies FilterEngine

## Phase 9: Detail View
- [x] `DetailView.swift` — ScrollView with DeviceCardView, TimelineView, conditional USBCCapabilityView, conditional PowerGraphView, EventHistoryTable
- [x] `DeviceCardView.swift` — large SF Symbol icon + product name + class badge + speed badge
- [x] `TimelineView.swift` — Canvas-based horizontal timeline of attach/detach events for selected device
- [ ] `USBCCapabilityView.swift` — badge grid: speed, max power, alt-modes, certification (from PDIdentity)
- [x] `EventHistoryTable.swift` — Table view of DeviceEvent rows: timestamp, type, locationID
- [x] `DetailController.swift` — ObservableObject; loads events from DatabaseManager for selected device

## Phase 10: Inspector Panel
- [x] `InspectorView.swift` — VStack of collapsible sections; collapsible trailing column
- [x] `QuickInfoSection.swift` — key-value grid of primary properties
- [x] `RawPropertiesSection.swift` — DisclosureGroup per IOKit property group
- [x] `LiveGraphsSection.swift` — hosts PowerGraphView + TransferRateGraphView
- [x] `PowerGraphView.swift` — Swift Charts line graph: watts over last 60s, live updates
- [ ] `TransferRateGraphView.swift` — Swift Charts line graph: MB/s for storage devices
- [x] `InspectorController.swift` — aggregates watcher data for the selected device

## Phase 11: Toolbar & Filtering
- [x] `ToolbarContent.swift` — Refresh button, Export button (opens ExportSheet), Filter toggle, Search field, Preferences button
- [x] `FilterEngine.swift` — ObservableObject; predicate filter on [USBDevice] by vendor/speed/class/date/power; publishes filteredDevices
- [x] `FilterBarView.swift` — HStack of filter token chips; revealed by Filter toolbar toggle

## Phase 12: Windows / Sheets
- [x] `ExportSheet.swift` — sheet: format picker (CSV/JSON/PDF/HTML), scope picker (selected device / all devices), save panel; calls ExportManager
- [x] `PreferencesWindow.swift` — Settings scene: notification prefs, DB retention days, graph update interval, launch-at-login toggle

## Phase 13: Status Bar
- [x] `StatusBarView.swift` — bottom overlay: "N devices · Last update: Xs ago" with live timer

## Phase 14: Wiring & Integration
- [x] Inject all watchers + DatabaseManager + FilterEngine as @EnvironmentObject in App.swift
- [x] Subscribe SidebarController to DeviceEventBus → update device list + persist via DatabaseManager
- [x] Wire FilterEngine.filteredDevices → SidebarController.displayDevices
- [x] Wire selectedDevice changes → DetailController.loadEvents() + InspectorController.observe()
- [x] Wire Export toolbar button → ExportSheet; wire Preferences button → PreferencesWindow

## Phase 15: Testing & Polish
- [ ] Test IOKit watcher callbacks fire on real USB attach/detach
- [ ] Verify PDVDO decoding with USB-C cables of known specs
- [ ] Test DB persistence and query with 1000+ events
- [ ] Test all four export formats produce valid output
- [ ] Check for IOKit object memory leaks (Instruments → Leaks)
- [ ] Verify window size / inspector state persists via @AppStorage
- [ ] `swift build -c release` — clean build, check binary size
- [ ] Run app for 1+ hour with USB devices plugging/unplugging — no crashes, memory stable
