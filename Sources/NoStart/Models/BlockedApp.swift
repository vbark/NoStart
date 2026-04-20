import Foundation

struct BlockedApp: Identifiable, Codable, Equatable, Hashable {
    var id: String { bundleID }
    let bundleID: String
    var name: String
    var isEnabled: Bool

    init(bundleID: String, name: String, isEnabled: Bool = true) {
        self.bundleID = bundleID
        self.name = name
        self.isEnabled = isEnabled
    }
}
