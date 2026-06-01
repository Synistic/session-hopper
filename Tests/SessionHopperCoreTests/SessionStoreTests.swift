import Foundation
import XCTest
@testable import SessionHopperCore

@MainActor
final class SessionStoreTests: XCTestCase {
    func testReloadStoresSessionsSortedByLastActivityDescending() {
        let older = ClaudeSession(
            id: "older-session",
            projectPath: URL(fileURLWithPath: "/Users/danielschmilinski/projects/old"),
            gitBranch: nil,
            lastActivity: Date(timeIntervalSince1970: 10)
        )
        let newer = ClaudeSession(
            id: "newer-session",
            projectPath: URL(fileURLWithPath: "/Users/danielschmilinski/projects/new"),
            gitBranch: "main",
            lastActivity: Date(timeIntervalSince1970: 20)
        )
        let store = SessionStore(loadSessions: { [older, newer] })

        store.reload()

        XCTAssertEqual(store.recentSessions.map(\.id), ["newer-session", "older-session"])
        XCTAssertNil(store.errorMessage)
    }

    func testReloadClearsSessionsAndStoresErrorMessageWhenScannerFails() {
        let store = SessionStore(loadSessions: { throw ScannerFailure.example })

        store.reload()

        XCTAssertEqual(store.recentSessions, [])
        XCTAssertNotNil(store.errorMessage)
        XCTAssertFalse(store.errorMessage?.isEmpty ?? true)
    }
}

private enum ScannerFailure: Error {
    case example
}
