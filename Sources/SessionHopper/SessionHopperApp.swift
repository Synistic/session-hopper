import SessionHopperCore
import SwiftUI

@main
struct SessionHopperApp: App {
    @StateObject private var services = AppServices.shared

    var body: some Scene {
        WindowGroup("Session Hopper") {
            SessionsWindowView(
                store: services.store,
                ghosttyLauncher: services.ghosttyLauncher,
                finderLauncher: services.finderLauncher
            )
            .task {
                services.start()
            }
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
