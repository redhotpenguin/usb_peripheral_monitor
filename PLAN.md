# USB Peripheral Monitor — Desktop App Implementation Plan

## Context

Native Swift/SwiftUI macOS desktop application for USB/peripheral monitoring. Watches all connected USB devices via IOKit in real-time. Three-pane UI: device tree sidebar, detail view with timeline + graphs, inspector panel. Exports to CSV/JSON/PDF/HTML. Persists event history in SQLite.

Specified in `usb peripheral monitor plan v3.pdf`. This build covers two targets:
- `USBMonitorCore` — shared library (watchers, models, decoders, database, export, analytics)
- `USBMonitorDesktop` — desktop app executable

CLI and Menu Bar targets are excluded for now; the package structure accommodates them later.

---

## Tech Stack

- **Language**: Swift 5.9+
- **UI**: SwiftUI + AppKit (NSWindow, NSSplitView)
- **Graphs**: Swift Charts (macOS 13+)
- **Database**: SQLite.swift `0.14.1`
- **IOKit**: `IOKit.framework` (device detection, USB-C PD decoding)
- **Minimum OS**: macOS 13 Ventura
- **Build tool**: Swift Package Manager

---

## Architecture

```
USBMonitorCore (library)
├── Watchers/          IOKit service monitoring & notifications
├── Models/            Data structures: USBDevice, USBCPort, PowerSource, PDIdentity, events
├── Decoders/          USB PD VDO decoding, device class labels, vendor name lookup
├── Database/          SQLite persistence via SQLite.swift
├── Export/            CSV / JSON / PDF / HTML generation
└── Analytics/         Bandwidth calc, USB topology tree

USBMonitorDesktop (executable)
├── App.swift          Entry point, environment object injection
├── ContentView.swift  Three-pane NavigationSplitView
├── Controllers/       Business logic for sidebar / detail / inspector
├── Views/             SwiftUI views
└── Windows/           Preferences + Export sheets
```

### Event Flow

```
IOKit callback → Watcher extracts io_service_t → USBDevice model created
    → DeviceEventBus (Combine PassthroughSubject)
        → DatabaseManager.persistEvent()
        → SidebarController updates device list
        → DetailController refreshes if selected device affected
        → InspectorController updates live data
```

---

## Window Layout (from PDF p.9)

```
┌─────────────────────────────────────────────────────────────────┐
│  Toolbar: [Refresh] [Export▼] [Filter] [⚙ Prefs] [🔍 Search]   │
├──────────────┬──────────────────────────┬────────────────────────┤
│ Sidebar      │ Detail View              │ Inspector              │
│ (200-300 pt) │ (flexible)               │ (250-350 pt)           │
│              │                          │                        │
│ ▼ Hubs       │  ┌──────────────────┐    │  Quick Info            │
│   Hub 1      │  │ [Icon] SanDisk   │    │  Vendor ID: 0x0781     │
│   Hub 2      │  │ Ultra USB 3.0    │    │  Product ID: 0x5581    │
│ ▶ Storage    │  │ Storage · USB 3  │    │  Speed: SuperSpeed     │
│   Drive 1    │  └──────────────────┘    │  Location: 0x14200000  │
│ ▶ Input      │                          │                        │
│   Keyboard   │  Connection Timeline     │  Technical Details ▼   │
│   Mouse      │  ━━━━━━━━━━━━━━━━━━━━    │    [IOKit properties]  │
│ ▶ USB-C      │                          │                        │
│   Cable 1    │  Event History           │  Live Graphs           │
│              │  [timestamp | type | …]  │  Power: ─────────      │
│ All (12)     │                          │  Rate:  ─────────      │
├──────────────┴──────────────────────────┴────────────────────────┤
│  12 devices connected · Last update: 2s ago                      │
└──────────────────────────────────────────────────────────────────┘
```

---

## Key Data Models

```swift
struct USBDevice: Identifiable, Codable {
    let id: UUID
    let vendorID: UInt16
    let productID: UInt16
    let vendorName: String?
    let productName: String?
    let deviceClass: DeviceClass
    let speed: USBSpeed
    let serialNumber: String?
    let locationID: UInt32
    let connectedAt: Date
    let parentHub: UUID?
    var rawProperties: [String: AnyCodable]
}
```

---

## Database Schema

```sql
CREATE TABLE devices (
    id TEXT PRIMARY KEY,
    vendor_id INTEGER, product_id INTEGER,
    vendor_name TEXT, product_name TEXT,
    device_class TEXT, speed TEXT, serial_number TEXT
);
CREATE TABLE events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id TEXT, event_type TEXT,
    timestamp DATETIME, location_id INTEGER, properties JSON,
    FOREIGN KEY(device_id) REFERENCES devices(id)
);
CREATE INDEX idx_events_timestamp ON events(timestamp);
CREATE INDEX idx_events_device ON events(device_id);
```

---

## Bundle & Entitlements

- Bundle ID: `com.yourcompany.usbmonitor.desktop`
- Entitlement: `com.apple.security.temporary-exception.iokit-user-client-class` for IOKit access
- Distribution: Direct DMG (App Store may require sandboxing exceptions)
