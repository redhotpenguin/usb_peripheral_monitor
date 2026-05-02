# OPS — USB Peripheral Monitor Desktop App

## Prerequisites

- macOS 13 Ventura or later
- Xcode 15+ (for Swift Charts and NavigationSplitView)
- Swift 5.9+ (included with Xcode or via `xcode-select --install`)
- Internet access on first build (fetches SQLite.swift from GitHub)

Verify your toolchain:
```
swift --version
xcode-select -p
```

---

## Build

```bash
# Resolve dependencies and compile (debug)
swift build

# Compile optimized release binary
swift build -c release
```

---

## Run

```bash
# Run from the package directory
swift run USBMonitorDesktop
```

The app opens a 1200×800 window. Plug in any USB device — it should appear in the sidebar within ~1 second.

**First launch**: the app creates `~/Library/Application Support/USBMonitor/events.db` automatically.

---

## Open in Xcode (for UI work)

```bash
open Package.swift
```

Select the `USBMonitorDesktop` scheme in the scheme picker, then Run (⌘R). SwiftUI previews work for individual view files.

---

## Run the release binary directly

```bash
.build/release/USBMonitorDesktop
```

---

## Verify IOKit device detection

1. Launch the app
2. Plug in a USB device (flash drive, keyboard, etc.)
3. It should appear immediately in the sidebar under the correct class section
4. Click it — detail view shows device card, inspector shows vendor/product IDs
5. Unplug — sidebar updates, a detach event appears in Event History

---

## Export test

1. With at least one device connected, click **Export** in the toolbar
2. Choose CSV, JSON, or HTML and save
3. Open the file to confirm it contains the connected device(s)

---

## Database inspection

```bash
# Open the live database in sqlite3
sqlite3 ~/Library/Application\ Support/USBMonitor/events.db

sqlite> SELECT * FROM devices;
sqlite> SELECT * FROM events ORDER BY timestamp DESC LIMIT 20;
sqlite> .quit
```

---

## Next Steps

### 1. Add app entitlements for IOKit access
Without entitlements the watcher may silently fail to enumerate all devices on a signed/sandboxed build.

Create `Sources/USBMonitorDesktop/USBMonitorDesktop.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.temporary-exception.iokit-user-client-class</key>
    <array>
        <string>IOUSBDeviceUserClientV2</string>
        <string>IOUSBInterfaceUserClientV2</string>
    </array>
</dict>
</plist>
```

Reference it in `Package.swift` by adding to the `USBMonitorDesktop` target:
```swift
.executableTarget(
    name: "USBMonitorDesktop",
    dependencies: ["USBMonitorCore"],
    path: "Sources/USBMonitorDesktop",
    swiftSettings: [
        .unsafeFlags(["-Xlinker", "-sectcreate",
                      "-Xlinker", "__TEXT",
                      "-Xlinker", "__entitlements",
                      "-Xlinker", "Sources/USBMonitorDesktop/USBMonitorDesktop.entitlements"])
    ]
)
```

For production, sign and entitle via Xcode or `codesign`.

### 2. Add an app icon
Place a 1024×1024 PNG in `Resources/Assets.xcassets/AppIcon.appiconset/` with the standard macOS icon sizes. A USB plug or cable icon works well.

### 3. Implement real PDF export
`ExportManager.exportPDF` currently returns HTML bytes. Replace it with a proper PDF render:
```swift
// In ExportSheet.swift, after generating HTML data:
let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 794, height: 1123))
webView.loadHTMLString(htmlString, baseURL: nil)
// wait for load, then call webView.createPDF(configuration:) async
```

### 4. Add USB-C capability view in detail pane
`USBCCapabilityView.swift` is listed in the TODO but not yet implemented. It should:
- Show in `DetailView` only when `device.deviceClass == .usbC`
- Display badges from the `PDIdentity` for the device: cable type, max speed, max power, alt-modes (DP, TB)
- Source data from `PDIdentityWatcher.identities` matched on `vendorID`

### 5. Wire real-time graph timer
The live power graph in the inspector samples only when `PowerSourceWatcher` fires. For storage devices, add a polling `Timer` in `InspectorController` to sample IOKit bandwidth counters every 2 seconds and populate a `transferRateSamples` array analogous to `powerSamples`.

### 6. Add comparison mode
Side-by-side view for two selected devices. Add a second `selectedDeviceID` binding in `ContentView`, a `ComparisonView` that lays two `DeviceCardView` + property grids side-by-side, and a toolbar toggle to enter comparison mode.

### 7. Add CLI and Menu Bar targets
The package structure already supports additional targets. Following the PDF plan:
- **Day 1-2 work done** (core engine)
- **Day 3**: Add `USBMonitorCLI` target — `main.swift` using `ArgumentParser`, `CLIFormatter` with ANSI colors, stream events to stdout
- **Day 4**: Add `USBMonitorMenuBar` target — `NSStatusBar` item, SwiftUI popover, `QuickNotificationManager`

Add both to `Package.swift` products and targets, linking `USBMonitorCore`.

### 8. Distribution: create a DMG
Once code-signed:
```bash
swift build -c release
# Create app bundle structure manually or via Xcode archive
# Then:
hdiutil create -volname "USB Monitor" \
  -srcfolder USBMonitorDesktop.app \
  -ov -format UDZO \
  USBMonitorDesktop.dmg
```

### 9. Increase vendor ID coverage
`VendorDatabase.swift` has ~45 entries. The full USB.org list has 3000+. Consider embedding the [usb-ids](https://github.com/vurt/usb-ids) dataset as a generated Swift literal or a bundled `.ids` file parsed at launch.

### 10. Persist window state
Add `@AppStorage` keys for inspector collapsed state and sidebar column width so they survive relaunches:
```swift
@AppStorage("inspectorVisible") private var showInspector = true
```
