import AppKit
import Darwin
import OSLog

final class AppKiller {
    private let store: BlocklistStore
    private let logger = Logger(subsystem: "dev.nostart.NoStart", category: "AppKiller")
    private var launchObserver: NSObjectProtocol?
    private let ownPID = ProcessInfo.processInfo.processIdentifier

    init(store: BlocklistStore) {
        self.store = store
    }

    func start() {
        stop()

        let center = NSWorkspace.shared.notificationCenter
        launchObserver = center.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.handle(note: note)
        }

        // Sweep already-running apps once on startup so the app is effective immediately.
        sweepRunning()

        logger.info("AppKiller started.")
    }

    func stop() {
        if let obs = launchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            launchObserver = nil
        }
    }

    func sweepRunning() {
        for app in NSWorkspace.shared.runningApplications {
            guard app.processIdentifier != ownPID,
                  let bid = app.bundleIdentifier,
                  store.isBlocked(bundleID: bid) else { continue }
            kill(app: app, reason: "sweep")
        }
    }

    // MARK: - Private

    private func handle(note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        guard app.processIdentifier != ownPID else { return }
        guard let bid = app.bundleIdentifier else { return }
        guard store.isBlocked(bundleID: bid) else { return }

        kill(app: app, reason: "launch")
    }

    private func kill(app: NSRunningApplication, reason: String) {
        let name = app.localizedName ?? app.bundleIdentifier ?? "(unknown)"
        let pid = app.processIdentifier
        logger.info("Killing \(name, privacy: .public) pid=\(pid) reason=\(reason, privacy: .public)")

        // 1) polite terminate
        _ = app.terminate()

        // 2) escalate if still alive after 50ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard !app.isTerminated else { return }
            self?.logger.info("forceTerminate \(name, privacy: .public)")
            _ = app.forceTerminate()

            // 3) final fallback: SIGKILL
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                guard !app.isTerminated else { return }
                self?.logger.info("SIGKILL \(name, privacy: .public) pid=\(pid)")
                _ = Darwin.kill(pid, SIGKILL)
            }
        }
    }
}
