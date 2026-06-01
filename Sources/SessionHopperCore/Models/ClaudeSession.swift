import Foundation

public struct ClaudeSession: Identifiable, Equatable, Sendable {
    public let id: String
    public let projectPath: URL
    public let gitBranch: String?
    public let lastActivity: Date

    public init(
        id: String,
        projectPath: URL,
        gitBranch: String?,
        lastActivity: Date
    ) {
        self.id = id
        self.projectPath = projectPath
        self.gitBranch = gitBranch
        self.lastActivity = lastActivity
    }
}
