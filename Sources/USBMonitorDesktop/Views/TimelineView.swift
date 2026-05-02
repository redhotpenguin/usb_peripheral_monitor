import SwiftUI
import USBMonitorCore

struct TimelineView: View {
    let device: USBDevice
    let events: [DeviceEvent]

    var body: some View {
        GroupBox("Connection Timeline") {
            if events.isEmpty {
                Text("No history yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                Canvas { ctx, size in
                    guard !events.isEmpty else { return }
                    let padding: Double = 16
                    let trackY = size.height / 2
                    let trackWidth = size.width - padding * 2

                    // Draw track line
                    let trackPath = Path { p in
                        p.move(to: CGPoint(x: padding, y: trackY))
                        p.addLine(to: CGPoint(x: padding + trackWidth, y: trackY))
                    }
                    ctx.stroke(trackPath, with: .color(.secondary.opacity(0.3)), lineWidth: 2)

                    // Time range
                    let timestamps = events.map(\.timestamp)
                    guard let minT = timestamps.min(), let maxT = timestamps.max() else { return }
                    let span = max(maxT.timeIntervalSince(minT), 60)

                    for event in events {
                        let t = event.timestamp.timeIntervalSince(minT) / span
                        let x = padding + t * trackWidth
                        let isAttach = event.eventType == .attach
                        let color: Color = isAttach ? .green : .red

                        // Draw dot
                        let dotRect = CGRect(x: x - 5, y: trackY - 5, width: 10, height: 10)
                        ctx.fill(Circle().path(in: dotRect), with: .color(color))

                        // Draw label
                        let label = isAttach ? "▲" : "▼"
                        ctx.draw(
                            Text(label).font(.caption2).foregroundColor(color),
                            at: CGPoint(x: x, y: isAttach ? trackY - 18 : trackY + 14)
                        )
                    }
                }
                .frame(height: 60)
            }
        }
    }
}
