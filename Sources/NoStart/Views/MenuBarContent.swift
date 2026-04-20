import SwiftUI
import AppKit

struct MenuBarContent: View {
    @EnvironmentObject var store: BlocklistStore
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Toggle("Enable NoStart", isOn: Binding(
            get: { store.globalEnabled },
            set: { store.setGlobalEnabled($0) }
        ))

        Divider()

        if store.entries.isEmpty {
            Text("No apps blocked")
        } else {
            let enabledCount = store.entries.filter(\.isEnabled).count
            Text("Blocking \(enabledCount) of \(store.entries.count) app(s)")
        }

        Divider()

        Button("Settings…") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        .keyboardShortcut(",")

        Button("Quit NoStart") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
