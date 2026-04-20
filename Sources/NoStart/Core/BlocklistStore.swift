import Foundation
import SwiftUI

final class BlocklistStore: ObservableObject {
    @Published private(set) var entries: [BlockedApp] = []
    @Published private(set) var globalEnabled: Bool = true

    private let fileURL: URL
    private let globalEnabledKey = "dev.nostart.globalEnabled"

    init() {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("NoStart", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("blocklist.json")

        if let stored = UserDefaults.standard.object(forKey: globalEnabledKey) as? Bool {
            self.globalEnabled = stored
        }
        load()
    }

    // MARK: - Persistence

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let list = try? JSONDecoder().decode([BlockedApp].self, from: data) else {
            entries = []
            return
        }
        entries = list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Mutations

    func add(_ app: BlockedApp) {
        guard !entries.contains(where: { $0.bundleID == app.bundleID }) else { return }
        entries.append(app)
        entries.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        save()
    }

    func remove(bundleID: String) {
        entries.removeAll { $0.bundleID == bundleID }
        save()
    }

    func toggle(bundleID: String) {
        guard let idx = entries.firstIndex(where: { $0.bundleID == bundleID }) else { return }
        entries[idx].isEnabled.toggle()
        save()
    }

    func setGlobalEnabled(_ value: Bool) {
        globalEnabled = value
        UserDefaults.standard.set(value, forKey: globalEnabledKey)
    }

    // MARK: - Queries

    func isBlocked(bundleID: String) -> Bool {
        guard globalEnabled else { return false }
        return entries.contains { $0.bundleID == bundleID && $0.isEnabled }
    }

    var storageLocation: URL { fileURL }
}
