import AppKit
import SessionHopperCore
import SwiftUI

@MainActor
struct SessionsWindowView: View {
    @ObservedObject var store: SessionStore

    let ghosttyLauncher: GhosttyLauncher
    let finderLauncher: FinderLauncher

    @State private var selection: ClaudeSession.ID?
    @State private var actionErrorMessage: String?

    private var selectedSession: ClaudeSession? {
        if let selection,
           let session = store.recentSessions.first(where: { $0.id == selection }) {
            return session
        }

        return store.recentSessions.first
    }

    var body: some View {
        NavigationSplitView {
            List(store.recentSessions.prefix(40), selection: $selection) { session in
                SessionSidebarRow(session: session)
                    .tag(session.id)
            }
            .navigationTitle("Sessions")
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Text("\(store.recentSessions.count) gefunden")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        store.reload()
                        actionErrorMessage = nil
                        selection = store.recentSessions.first?.id
                    } label: {
                        Label("Aktualisieren", systemImage: "arrow.clockwise")
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Aktualisieren")
                }
                .padding(10)
            }
        } detail: {
            if let selectedSession {
                SessionDetailView(
                    session: selectedSession,
                    ghosttyLauncher: ghosttyLauncher,
                    finderLauncher: finderLauncher,
                    actionErrorMessage: $actionErrorMessage
                )
            } else {
                ContentUnavailableView(
                    "Keine Sessions gefunden",
                    systemImage: "bolt.slash",
                    description: Text("Claude-Code-Sessions werden lokal aus ~/.claude/projects gelesen.")
                )
            }
        }
        .frame(minWidth: 780, minHeight: 480)
        .onAppear {
            if selection == nil {
                selection = store.recentSessions.first?.id
            }
        }
    }
}

private struct SessionSidebarRow: View {
    let session: ClaudeSession

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(session.projectName)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(session.shortID)
                    if let gitBranch = session.gitBranch {
                        Text(gitBranch)
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "terminal")
                .foregroundStyle(.tint)
        }
    }
}

private struct SessionDetailView: View {
    let session: ClaudeSession
    let ghosttyLauncher: GhosttyLauncher
    let finderLauncher: FinderLauncher

    @Binding var actionErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.projectName)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(session.projectPath.path)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Text(session.lastActivity.sessionHopperRelativeLabel())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    openInGhostty()
                } label: {
                    Label("In Ghostty oeffnen", systemImage: "terminal")
                }
                .disabled(!ghosttyLauncher.canOpen(session))
                .keyboardShortcut(.return, modifiers: .command)

                Button {
                    finderLauncher.open(session)
                } label: {
                    Label("Im Finder oeffnen", systemImage: "folder")
                }
                .disabled(!finderLauncher.canOpen(session))

                Button {
                    copySessionID()
                } label: {
                    Label("Session-ID kopieren", systemImage: "doc.on.doc")
                }
            }

            Divider()

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("Session-ID")
                        .foregroundStyle(.secondary)
                    Text(session.id)
                        .textSelection(.enabled)
                }

                if let gitBranch = session.gitBranch {
                    GridRow {
                        Text("Branch")
                            .foregroundStyle(.secondary)
                        Text(gitBranch)
                            .textSelection(.enabled)
                    }
                }

                GridRow {
                    Text("Befehl")
                        .foregroundStyle(.secondary)
                    Text("claude --dangerously-skip-permissions --resume \(session.id)")
                        .textSelection(.enabled)
                }
            }
            .font(.callout)

            if let actionErrorMessage {
                Text(actionErrorMessage)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding(24)
    }

    private func openInGhostty() {
        do {
            try ghosttyLauncher.open(session)
            actionErrorMessage = nil
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    private func copySessionID() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(session.id, forType: .string)
        actionErrorMessage = nil
    }
}

private extension ClaudeSession {
    var projectName: String {
        let lastPathComponent = projectPath.lastPathComponent
        return lastPathComponent.isEmpty ? projectPath.path : lastPathComponent
    }

    var shortID: String {
        String(id.prefix(8))
    }
}
