import SwiftUI

struct PreferencesView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("dbRetentionDays") private var dbRetentionDays = 30
    @AppStorage("graphUpdateInterval") private var graphUpdateInterval = 2.0

    var body: some View {
        TabView {
            GeneralPrefsTab(
                notificationsEnabled: $notificationsEnabled
            )
            .tabItem { Label("General", systemImage: "gearshape") }

            DataPrefsTab(
                dbRetentionDays: $dbRetentionDays,
                graphUpdateInterval: $graphUpdateInterval
            )
            .tabItem { Label("Data", systemImage: "cylinder") }
        }
        .frame(width: 480, height: 300)
    }
}

private struct GeneralPrefsTab: View {
    @Binding var notificationsEnabled: Bool

    var body: some View {
        Form {
            Toggle("Show notifications on device connect/disconnect", isOn: $notificationsEnabled)
        }
        .formStyle(.grouped)
        .padding()
    }
}

private struct DataPrefsTab: View {
    @Binding var dbRetentionDays: Int
    @Binding var graphUpdateInterval: Double

    var body: some View {
        Form {
            Stepper("Keep event history for \(dbRetentionDays) days", value: $dbRetentionDays, in: 1...365)

            VStack(alignment: .leading) {
                Text("Graph update interval: \(graphUpdateInterval, specifier: "%.0f")s")
                Slider(value: $graphUpdateInterval, in: 1...10, step: 1)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
