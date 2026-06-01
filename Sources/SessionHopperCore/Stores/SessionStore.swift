import Combine
import Foundation

@MainActor
public final class SessionStore: ObservableObject {
    @Published public private(set) var recentSessions: [ClaudeSession]
    @Published public private(set) var errorMessage: String?

    private let loadSessions: () throws -> [ClaudeSession]

    public convenience init(scanner: ClaudeSessionScanner = ClaudeSessionScanner()) {
        self.init(loadSessions: scanner.scan)
    }

    public init(loadSessions: @escaping () throws -> [ClaudeSession]) {
        self.loadSessions = loadSessions
        recentSessions = []
        errorMessage = nil
    }

    public func reload() {
        do {
            recentSessions = try loadSessions().sorted { lhs, rhs in
                lhs.lastActivity > rhs.lastActivity
            }
            errorMessage = nil
        } catch {
            recentSessions = []
            errorMessage = error.localizedDescription
        }
    }
}
