import AppKit
import Foundation

public struct FinderLauncher: Sendable {
    public init() {}

    public func canOpen(_ session: ClaudeSession) -> Bool {
        FileManager.default.sessionHopperDirectoryExists(at: session.projectPath)
    }

    @MainActor
    public func open(_ session: ClaudeSession) {
        NSWorkspace.shared.open(session.projectPath)
    }
}

private extension FileManager {
    func sessionHopperDirectoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
