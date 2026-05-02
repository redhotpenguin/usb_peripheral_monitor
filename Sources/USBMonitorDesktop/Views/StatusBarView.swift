import SwiftUI

struct StatusBarView: View {
    let deviceCount: Int
    let lastUpdate: Date

    var body: some View {
        HStack {
            Text("\(deviceCount) device\(deviceCount == 1 ? "" : "s") connected")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("Last update: \(lastUpdate, style: .relative) ago")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
