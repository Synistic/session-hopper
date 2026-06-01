import AppKit
import Foundation
import SessionHopperCore

@MainActor
final class AppServices: ObservableObject {
    static let shared = AppServices()

    let store = SessionStore()
    let ghosttyLauncher = GhosttyLauncher()
    let finderLauncher = FinderLauncher()

    private var statusBarController: StatusBarController?
    private var didStart = false

    private init() {}

    func start() {
        guard !didStart else {
            return
        }

        didStart = true
        NSApp.setActivationPolicy(.regular)
        NSApp.applicationIconImage = AppIconFactory.makeAppIcon(size: 512)
        installStatusBar()
        store.reload()
    }

    func installStatusBar() {
        if statusBarController == nil {
            statusBarController = StatusBarController(
                store: store,
                ghosttyLauncher: ghosttyLauncher,
                finderLauncher: finderLauncher
            )
        }
    }
}
