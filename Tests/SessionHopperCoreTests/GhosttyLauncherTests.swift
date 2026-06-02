import Foundation
import XCTest
@testable import SessionHopperCore

final class GhosttyLauncherTests: XCTestCase {
    func testMakeOpenArgumentsBuildsGhosttyResumeCommand() {
        let session = ClaudeSession(
            id: "faa71b5b-12c7-4b76-96e6-eb36ada25ff5",
            projectPath: URL(fileURLWithPath: "/Users/danielschmilinski/projects/zwoeins-os"),
            gitBranch: "codex/session-hopper",
            lastActivity: Date(timeIntervalSince1970: 0)
        )
        let launcher = GhosttyLauncher(
            claudeExecutablePath: "/Users/danielschmilinski/.local/bin/claude"
        )

        XCTAssertEqual(
            launcher.makeOpenArguments(for: session),
            [
                "-na",
                "/Applications/Ghostty.app",
                "--args",
                "--working-directory=/Users/danielschmilinski/projects/zwoeins-os",
                "-e",
                "/bin/zsh",
                "-lc",
                "exec /Users/danielschmilinski/.local/bin/claude --dangerously-skip-permissions --resume faa71b5b-12c7-4b76-96e6-eb36ada25ff5"
            ]
        )
    }
}
