import Foundation
import XCTest
@testable import SessionHopperCore

final class ClaudeSessionScannerTests: XCTestCase {
    func testScannerUsesLastTimestampedMetadataEntry() throws {
        let root = try TestDirectory()
        let project = root.url.appending(path: "-Users-danielschmilinski-projects-zwoeins-os")
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        let sessionFile = project.appending(path: "faa71b5b-12c7-4b76-96e6-2c8a541c84c2.jsonl")
        let cwd = "/Users/danielschmilinski/projects/zwoeins-os"

        let jsonl = """
        {"type":"user","sessionId":"faa71b5b-12c7-4b76-96e6-2c8a541c84c2","cwd":"\(cwd)","gitBranch":"main","timestamp":"2026-06-01T18:00:00.000Z"}
        {"type":"assistant","sessionId":"faa71b5b-12c7-4b76-96e6-2c8a541c84c2","cwd":"\(cwd)","gitBranch":"codex/session-hopper","timestamp":"2026-06-01T18:43:55.899Z"}
        {"type":"mode","sessionId":"faa71b5b-12c7-4b76-96e6-2c8a541c84c2","mode":"default"}
        """
        try jsonl.write(to: sessionFile, atomically: true, encoding: .utf8)

        let scanner = ClaudeSessionScanner(projectsDirectory: root.url)
        let sessions = try scanner.scan()

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].id, "faa71b5b-12c7-4b76-96e6-2c8a541c84c2")
        XCTAssertEqual(sessions[0].projectPath.path, cwd)
        XCTAssertEqual(sessions[0].gitBranch, "codex/session-hopper")
        XCTAssertEqual(sessions[0].lastActivity, formatter.date(from: "2026-06-01T18:43:55.899Z"))
    }

    func testScannerIgnoresInvalidJsonlRows() throws {
        let root = try TestDirectory()
        let project = root.url.appending(path: "-Users-danielschmilinski-projects-dsc-website-astro")
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        let sessionFile = project.appending(path: "3e77943a-6e3b-4439-bce6-eb36ada25ff5.jsonl")

        let jsonl = """
        this is not json
        {"type":"assistant","sessionId":"3e77943a-6e3b-4439-bce6-eb36ada25ff5","cwd":"/Users/danielschmilinski/projects/dsc-website-astro","timestamp":"2026-06-01T08:41:00.000Z"}
        {"type":"mode","sessionId":"3e77943a-6e3b-4439-bce6-eb36ada25ff5","mode":"default"}
        """
        try jsonl.write(to: sessionFile, atomically: true, encoding: .utf8)

        let sessions = try ClaudeSessionScanner(projectsDirectory: root.url).scan()

        XCTAssertEqual(sessions.map(\.id), ["3e77943a-6e3b-4439-bce6-eb36ada25ff5"])
    }

    func testScannerReturnsEmptyListWhenProjectsDirectoryIsMissing() throws {
        let root = try TestDirectory()
        let missingDirectory = root.url.appending(path: "missing")

        let sessions = try ClaudeSessionScanner(projectsDirectory: missingDirectory).scan()

        XCTAssertEqual(sessions, [])
    }

    func testScannerSortsSessionsByLastActivityDescending() throws {
        let root = try TestDirectory()
        let olderProject = root.url.appending(path: "-Users-danielschmilinski-projects-old")
        let newerProject = root.url.appending(path: "-Users-danielschmilinski-projects-new")
        try FileManager.default.createDirectory(at: olderProject, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: newerProject, withIntermediateDirectories: true)

        try """
        {"type":"assistant","sessionId":"older-session","cwd":"/Users/danielschmilinski/projects/old","timestamp":"2026-06-01T08:00:00.000Z"}
        """.write(to: olderProject.appending(path: "older-session.jsonl"), atomically: true, encoding: .utf8)
        try """
        {"type":"assistant","sessionId":"newer-session","cwd":"/Users/danielschmilinski/projects/new","timestamp":"2026-06-01T20:00:00.000Z"}
        """.write(to: newerProject.appending(path: "newer-session.jsonl"), atomically: true, encoding: .utf8)

        let sessions = try ClaudeSessionScanner(projectsDirectory: root.url).scan()

        XCTAssertEqual(sessions.map(\.id), ["newer-session", "older-session"])
    }
}

private struct TestDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appending(path: "SessionHopperTests")
            .appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
