import Foundation

public struct GhosttyLauncher: Sendable {
    public let openExecutable: URL
    public let ghosttyAppPath: String
    public let claudeExecutablePath: String

    public init(
        openExecutable: URL = URL(fileURLWithPath: "/usr/bin/open"),
        ghosttyAppPath: String = "/Applications/Ghostty.app",
        claudeExecutablePath: String = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: ".local/bin/claude")
            .path
    ) {
        self.openExecutable = openExecutable
        self.ghosttyAppPath = ghosttyAppPath
        self.claudeExecutablePath = claudeExecutablePath
    }

    public func canOpen(_ session: ClaudeSession) -> Bool {
        FileManager.default.fileExists(atPath: ghosttyAppPath)
            && FileManager.default.fileExists(atPath: claudeExecutablePath)
            && FileManager.default.sessionHopperDirectoryExists(at: session.projectPath)
    }

    public func makeOpenArguments(for session: ClaudeSession) -> [String] {
        [
            "-na",
            ghosttyAppPath,
            "--args",
            "--working-directory=\(session.projectPath.path)",
            "-e",
            "/bin/zsh",
            "-lc",
            "exec \(claudeExecutablePath.sessionHopperShellQuoted) --dangerously-skip-permissions --resume \(session.id.sessionHopperShellQuoted)"
        ]
    }

    public func open(_ session: ClaudeSession) throws {
        let process = Process()
        process.executableURL = openExecutable
        process.arguments = makeOpenArguments(for: session)
        try process.run()
    }
}

private extension String {
    var sessionHopperShellQuoted: String {
        let safeCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_@%+=:,./-")
        if unicodeScalars.allSatisfy({ safeCharacters.contains($0) }) {
            return self
        }

        return "'" + replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

private extension FileManager {
    func sessionHopperDirectoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
