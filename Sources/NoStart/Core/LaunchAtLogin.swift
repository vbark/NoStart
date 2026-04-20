import Foundation
import ServiceManagement

final class LaunchAtLogin: ObservableObject {
    @Published private(set) var isEnabled: Bool = false
    @Published private(set) var lastError: String?

    init() {
        refresh()
    }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ value: Bool) {
        lastError = nil
        do {
            if value {
                if SMAppService.mainApp.status == .enabled { isEnabled = true; return }
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refresh()
        } catch {
            lastError = error.localizedDescription
            NSLog("NoStart LaunchAtLogin error: \(error)")
            refresh()
        }
    }
}
