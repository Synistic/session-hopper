import Foundation

public struct ClaudeSessionScanner: Sendable {
    public let projectsDirectory: URL

    public init(
        projectsDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: ".claude/projects")
    ) {
        self.projectsDirectory = projectsDirectory
    }

    public func scan() throws -> [ClaudeSession] {
        guard FileManager.default.fileExists(atPath: projectsDirectory.path) else {
            return []
        }

        let sessionFiles = jsonlFiles(in: projectsDirectory)
        let sessions = sessionFiles.compactMap { session(from: $0) }

        return sessions.sorted { lhs, rhs in
            lhs.lastActivity > rhs.lastActivity
        }
    }

    private func jsonlFiles(in directory: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator.compactMap { item -> URL? in
            guard let url = item as? URL, url.pathExtension == "jsonl" else {
                return nil
            }
            return url
        }
    }

    private func session(from fileURL: URL) -> ClaudeSession? {
        guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return nil
        }

        let decoder = JSONDecoder()
        var latestSession: ClaudeSession?

        for line in contents.split(whereSeparator: \.isNewline) {
            guard let data = String(line).data(using: .utf8),
                  let metadata = try? decoder.decode(SessionMetadata.self, from: data),
                  let session = metadata.session else {
                continue
            }

            latestSession = session
        }

        return latestSession
    }
}

private struct SessionMetadata: Decodable {
    let sessionId: String?
    let cwd: String?
    let gitBranch: String?
    let timestamp: String?

    var session: ClaudeSession? {
        guard let sessionId = sessionId?.trimmedNonEmpty,
              let cwd = cwd?.trimmedNonEmpty,
              let timestamp = timestamp?.trimmedNonEmpty,
              let lastActivity = Date.sessionHopperDate(from: timestamp) else {
            return nil
        }

        return ClaudeSession(
            id: sessionId,
            projectPath: URL(fileURLWithPath: cwd),
            gitBranch: gitBranch?.trimmedNonEmpty,
            lastActivity: lastActivity
        )
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension Date {
    static func sessionHopperDate(from value: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = fractionalFormatter.date(from: value) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
