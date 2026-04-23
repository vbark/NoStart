import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var store: BlocklistStore
    @EnvironmentObject var launchAtLogin: LaunchAtLogin

    @AppStorage("dev.nostart.blocklistExpanded") private var isBlocklistExpanded: Bool = false
    @AppStorage("dev.nostart.confirmBeforeRemove") private var confirmBeforeRemove: Bool = true

    @State private var pendingRemovalBundleID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            statusCard
            generalCard
            blocklistCard
        }
        .padding(18)
        .frame(minWidth: 480, idealWidth: 540, maxWidth: 720)
        .fixedSize(horizontal: false, vertical: true)
        .background(Theme.windowBackground)
        .tint(Theme.accent)
        .background(WindowAccessor { window in
            styleWindow(window)
        })
        .confirmationDialog(
            "Remove this application from the blocklist?",
            isPresented: Binding(
                get: { pendingRemovalBundleID != nil },
                set: { if !$0 { pendingRemovalBundleID = nil } }
            ),
            presenting: pendingRemovalBundleID
        ) { bundleID in
            Button("Remove", role: .destructive) {
                store.remove(bundleID: bundleID)
                pendingRemovalBundleID = nil
            }
            Button("Cancel", role: .cancel) {
                pendingRemovalBundleID = nil
            }
        } message: { bundleID in
            if let entry = store.entries.first(where: { $0.bundleID == bundleID }) {
                Text("“\(entry.name)” will no longer be blocked.")
            }
        }
        .environment(\.removeEntry, { bundleID in
            if confirmBeforeRemove {
                pendingRemovalBundleID = bundleID
            } else {
                store.remove(bundleID: bundleID)
            }
        })
    }

    // MARK: - Status

    private var statusCard: some View {
        Card {
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
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Toggle("", isOn: Binding(
                    get: { store.globalEnabled },
                    set: { store.setGlobalEnabled($0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.large)
            }
        }
    }

    // MARK: - General

    private var generalCard: some View {
        SectionCard(title: "General") {
            SettingRow {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start at login")
                    Text("Automatically launch NoStart when you log in to your Mac.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } trailing: {
                Toggle("", isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { launchAtLogin.setEnabled($0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
            }

            Divider().opacity(0.3)

            SettingRow {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Confirm before removing")
                    Text("Ask before removing an app from the blocklist.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } trailing: {
                Toggle("", isOn: $confirmBeforeRemove)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            Divider().opacity(0.3)

            SettingRow {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Blocklist file")
                    Text(store.storageLocation.path)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
            } trailing: {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([store.storageLocation])
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .help("Reveal in Finder")
            }
        }
    }

    // MARK: - Blocklist

    private var blocklistCard: some View {
        Card {
            VStack(spacing: 0) {
                Button {
                    withAnimation(Self.expandAnimation) {
                        isBlocklistExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isBlocklistExpanded ? 90 : 0))

                        Text("Blocked Applications")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        countBadge

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isBlocklistExpanded {
                    VStack(spacing: 0) {
                        Divider().opacity(0.3).padding(.vertical, 10)

                        if store.entries.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 4) {
                                ForEach(store.entries) { entry in
                                    EntryRow(entry: entry)
                                }
                            }
                        }
                    }
                    .transition(.opacity)
                }

                Divider().opacity(0.3).padding(.vertical, 10)

                Button {
                    pickAndAdd()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.tint)
                        Text("Add Application…")
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut("n")
            }
        }
    }

    private var countBadge: some View {
        let total = store.entries.count
        let active = store.entries.filter(\.isEnabled).count
        return Group {
            if total > 0 {
                Text("\(active)/\(total)")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(Theme.elevated.opacity(0.6))
                    )
            } else {
                Text("empty")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 6) {
                Image(systemName: "tray")
                    .font(.system(size: 28))
                    .foregroundStyle(.tertiary)
                Text("No apps blocked yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Click “Add Application…” to get started.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 14)
            Spacer()
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

        var added = false
        for url in panel.urls {
            guard let bundle = Bundle(url: url), let bid = bundle.bundleIdentifier else { continue }
            let name = (bundle.infoDictionary?["CFBundleName"] as? String)
                ?? (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
                ?? url.deletingPathExtension().lastPathComponent
            store.add(BlockedApp(bundleID: bid, name: name, isEnabled: true))
            added = true
        }

        // Auto-expand the list when the user adds something so they see the result.
        if added {
            withAnimation(Self.expandAnimation) { isBlocklistExpanded = true }
        }
    }

    // MARK: - Animation constants

    fileprivate static let expandAnimation: Animation = .easeInOut(duration: 0.22)

    // MARK: - Window styling

    private func styleWindow(_ window: NSWindow) {
        // Make the titlebar blend into the content so the top bar matches the
        // window background instead of showing the default system chrome.
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = true

        // NSColor(_: SwiftUI.Color) preserves the dynamic dark/light resolution
        // configured in Theme.
        window.backgroundColor = NSColor(Theme.windowBackground)

        // Match NSWindow's live-resize animation timing to our SwiftUI
        // animation so expanding/collapsing the blocklist doesn't feel like
        // the window is snapping to a new size.
        if let contentView = window.contentView {
            contentView.wantsLayer = true
        }
    }
}

// MARK: - Window accessor

private struct WindowAccessor: NSViewRepresentable {
    let configure: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            if let window = view.window {
                configure(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                configure(window)
            }
        }
    }
}

// MARK: - Card wrappers

private struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.elevated.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.04), lineWidth: 1)
            )
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    content
                }
            }
        }
    }
}

private struct SettingRow<Label: View, Trailing: View>: View {
    @ViewBuilder var label: Label
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            label
                .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Environment plumbing for row removal

private struct RemoveEntryKey: EnvironmentKey {
    static let defaultValue: (String) -> Void = { _ in }
}

private extension EnvironmentValues {
    var removeEntry: (String) -> Void {
        get { self[RemoveEntryKey.self] }
        set { self[RemoveEntryKey.self] = newValue }
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
    @Environment(\.removeEntry) private var removeEntry

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
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: Binding(
                get: { entry.isEnabled },
                set: { _ in store.toggle(bundleID: entry.bundleID) }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()
            .help(entry.isEnabled ? "Blocking enabled" : "Blocking disabled")

            Button {
                removeEntry(entry.bundleID)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.danger.opacity(0.85))
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .help("Remove from blocklist")
        }
        .padding(.vertical, 4)
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
