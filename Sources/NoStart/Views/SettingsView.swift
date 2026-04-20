import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var store: BlocklistStore
    @EnvironmentObject var launchAtLogin: LaunchAtLogin

    var body: some View {
        Form {
            statusSection
            blocklistSection
            preferencesSection
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Theme.windowBackground)
        .tint(Theme.accent)
        .frame(minWidth: 560, idealWidth: 580, minHeight: 560, idealHeight: 620)
    }

    // MARK: - Status

    private var statusSection: some View {
        Section {
            HStack(alignment: .center, spacing: 14) {
                StatusBadge(isActive: store.globalEnabled)

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.globalEnabled ? "NoStart is active" : "NoStart is paused")
                        .font(.headline)
                    Text(store.globalEnabled
                         ? "Listed apps are killed the moment they launch."
                         : "Turn on to start blocking apps again.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 16)

                Toggle("", isOn: Binding(
                    get: { store.globalEnabled },
                    set: { store.setGlobalEnabled($0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.large)
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Blocklist

    private var blocklistSection: some View {
        Section {
            if store.entries.isEmpty {
                emptyState
            } else {
                ForEach(store.entries) { entry in
                    EntryRow(entry: entry)
                }
            }

            Button {
                pickAndAdd()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.tint)
                    Text("Add Application…")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("n")
        } header: {
            Text("Blocked Applications")
        } footer: {
            Text("Apps are matched by bundle identifier, so renames and updates don't break rules.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 6) {
                Image(systemName: "tray")
                    .font(.system(size: 32))
                    .foregroundStyle(.tertiary)
                Text("No apps blocked yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 24)
            Spacer()
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section("General") {
            Toggle(isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start at login")
                    Text("Automatically launch NoStart when you log in to your Mac.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Picker

    private func pickAndAdd() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [UTType.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Select one or more applications to block"
        panel.prompt = "Block"
        panel.treatsFilePackagesAsDirectories = false

        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { return }

        for url in panel.urls {
            guard let bundle = Bundle(url: url), let bid = bundle.bundleIdentifier else { continue }
            let name = (bundle.infoDictionary?["CFBundleName"] as? String)
                ?? (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
                ?? url.deletingPathExtension().lastPathComponent
            store.add(BlockedApp(bundleID: bid, name: name, isEnabled: true))
        }
    }
}

// MARK: - StatusBadge

struct StatusBadge: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill((isActive ? Theme.active : Theme.paused).opacity(0.18))
            Image(systemName: isActive ? "checkmark.seal.fill" : "pause.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(isActive ? Theme.active : Theme.paused)
        }
        .frame(width: 42, height: 42)
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .accessibilityLabel(isActive ? "Active" : "Paused")
    }
}

// MARK: - EntryRow

struct EntryRow: View {
    let entry: BlockedApp
    @EnvironmentObject var store: BlocklistStore

    var body: some View {
        HStack(spacing: 10) {
            iconView
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.name)
                Text(entry.bundleID)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { entry.isEnabled },
                set: { _ in store.toggle(bundleID: entry.bundleID) }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()
            .help(entry.isEnabled ? "Blocking enabled" : "Blocking disabled")

            Button {
                store.remove(bundleID: entry.bundleID)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.danger.opacity(0.85))
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .help("Remove from blocklist")
        }
        .padding(.vertical, 2)
        .opacity(entry.isEnabled ? 1.0 : 0.55)
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon = Self.icon(for: entry.bundleID) {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
        } else {
            Image(systemName: "app.dashed")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
        }
    }

    private static func icon(for bundleID: String) -> NSImage? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }
}
