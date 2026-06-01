import AppKit
import Combine
import os
import SessionHopperCore

@MainActor
final class StatusBarController: NSObject {
    private static let logger = Logger(
        subsystem: "com.danielschmilinski.SessionHopper",
        category: "StatusBar"
    )

    private let statusItem: NSStatusItem
    private let store: SessionStore
    private let ghosttyLauncher: GhosttyLauncher
    private let finderLauncher: FinderLauncher
    private var cancellables: Set<AnyCancellable> = []

    init(
        store: SessionStore,
        ghosttyLauncher: GhosttyLauncher,
        finderLauncher: FinderLauncher
    ) {
        self.store = store
        self.ghosttyLauncher = ghosttyLauncher
        self.finderLauncher = finderLauncher
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureButton()
        bindStore()
        rebuildMenu()
    }

    private func configureButton() {
        guard let button = statusItem.button else {
            Self.logger.error("Could not create NSStatusItem button")
            return
        }

        button.image = AppIconFactory.makeStatusBarIcon()
        button.title = "SH"
        button.imagePosition = .imageLeading
        button.font = .systemFont(ofSize: 11, weight: .semibold)
        button.toolTip = "Session Hopper"
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

        Self.logger.info("Installed Session Hopper status item")
    }

    private func bindStore() {
        store.$recentSessions
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)

        store.$errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "Session Hopper", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("Fenster anzeigen", action: #selector(showWindow)))
        menu.addItem(menuItem("Aktualisieren", action: #selector(refresh)))

        if let errorMessage = store.errorMessage {
            menu.addItem(NSMenuItem.separator())
            let errorItem = NSMenuItem(title: errorMessage, action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        menu.addItem(NSMenuItem.separator())

        if store.recentSessions.isEmpty {
            let emptyItem = NSMenuItem(title: "Keine Sessions gefunden", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for session in store.recentSessions.prefix(20) {
                menu.addItem(sessionMenuItem(for: session))
            }
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("Beenden", action: #selector(quit)))

        statusItem.menu = menu
    }

    private func sessionMenuItem(for session: ClaudeSession) -> NSMenuItem {
        let item = NSMenuItem(title: menuTitle(for: session), action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        let ghosttyItem = menuItem("In Ghostty oeffnen", action: #selector(openInGhostty(_:)))
        ghosttyItem.representedObject = session.id
        ghosttyItem.isEnabled = ghosttyLauncher.canOpen(session)
        submenu.addItem(ghosttyItem)

        let finderItem = menuItem("Im Finder oeffnen", action: #selector(openInFinder(_:)))
        finderItem.representedObject = session.id
        finderItem.isEnabled = finderLauncher.canOpen(session)
        submenu.addItem(finderItem)

        let copyItem = menuItem("Session-ID kopieren", action: #selector(copySessionID(_:)))
        copyItem.representedObject = session.id
        submenu.addItem(copyItem)

        item.submenu = submenu
        return item
    }

    private func menuItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func session(with id: String?) -> ClaudeSession? {
        guard let id else {
            return nil
        }

        return store.recentSessions.first { $0.id == id }
    }

    private func menuTitle(for session: ClaudeSession) -> String {
        let branch = session.gitBranch.map { " @ \($0)" } ?? ""
        return "\(projectName(for: session))\(branch) | \(String(session.id.prefix(8)))"
    }

    private func projectName(for session: ClaudeSession) -> String {
        let name = session.projectPath.lastPathComponent
        return name.isEmpty ? session.projectPath.path : name
    }

    @objc private func showWindow() {
        NSApp.activate(ignoringOtherApps: true)

        if let window = NSApp.windows.first(where: { $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func refresh() {
        store.reload()
    }

    @objc private func openInGhostty(_ sender: NSMenuItem) {
        guard let session = session(with: sender.representedObject as? String) else {
            return
        }

        try? ghosttyLauncher.open(session)
    }

    @objc private func openInFinder(_ sender: NSMenuItem) {
        guard let session = session(with: sender.representedObject as? String) else {
            return
        }

        finderLauncher.open(session)
    }

    @objc private func copySessionID(_ sender: NSMenuItem) {
        guard let session = session(with: sender.representedObject as? String) else {
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(session.id, forType: .string)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
