import SwiftUI
import AppKit

@main
struct NoStartApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("NoStart", systemImage: "xmark.octagon.fill") {
            MenuBarContent()
                .environmentObject(appDelegate.store)
                .environmentObject(appDelegate.launchAtLogin)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(appDelegate.store)
                .environmentObject(appDelegate.launchAtLogin)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let store = BlocklistStore()
    let launchAtLogin = LaunchAtLogin()
    private var killer: AppKiller?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let k = AppKiller(store: store)
        k.start()
        self.killer = k
    }

    func applicationWillTerminate(_ notification: Notification) {
        killer?.stop()
    }
}
