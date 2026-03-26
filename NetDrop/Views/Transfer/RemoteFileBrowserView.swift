import SwiftUI

struct RemoteFileBrowserView: View {
    @Environment(TransferManager.self) private var transferManager
    let favorite: Favorite

    @State private var currentPath: String
    @State private var entries: [RemoteFileEntry] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var pathHistory: [String] = []

    init(favorite: Favorite) {
        self.favorite = favorite
        self._currentPath = State(initialValue: favorite.remotePath)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Breadcrumb path bar
            HStack(spacing: 4) {
                Button {
                    navigateTo("/")
                } label: {
                    Image(systemName: "house")
                }
                .buttonStyle(.borderless)

                if !pathHistory.isEmpty {
                    Button {
                        goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.borderless)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Text(currentPath)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button {
                    Task { await loadDirectory() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(.bar)

            Divider()

            // File list
            if isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                ContentUnavailableView {
                    Label("Connection Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if entries.isEmpty {
                ContentUnavailableView(
                    "Empty Directory",
                    systemImage: "folder",
                    description: Text(currentPath)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(entries) { entry in
                    RemoteFileRow(entry: entry)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            if entry.isDirectory {
                                navigateTo(entry.path)
                            } else {
                                downloadFile(entry)
                            }
                        }
                        .contextMenu {
                            if entry.isDirectory {
                                Button("Open") { navigateTo(entry.path) }
                            }
                            Button("Download…") { downloadFile(entry) }
                            Divider()
                            Button("Delete", role: .destructive) {
                                deleteFile(entry)
                            }
                        }
                }
                .listStyle(.inset)
            }
        }
        .task {
            await loadDirectory()
        }
    }

    private func loadDirectory() async {
        isLoading = true
        error = nil

        do {
            entries = try await SSHService.listDirectory(path: currentPath, favorite: favorite)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func navigateTo(_ path: String) {
        pathHistory.append(currentPath)
        currentPath = path
        Task { await loadDirectory() }
    }

    private func goBack() {
        guard let previous = pathHistory.popLast() else { return }
        currentPath = previous
        Task { await loadDirectory() }
    }

    private func downloadFile(_ entry: RemoteFileEntry) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = entry.name
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            transferManager.download(
                remotePath: entry.path,
                localPath: url.path,
                favorite: favorite
            )
        }
    }

    private func deleteFile(_ entry: RemoteFileEntry) {
        Task {
            try? await SSHService.remove(path: entry.path, favorite: favorite)
            await loadDirectory()
        }
    }
}

struct RemoteFileRow: View {
    let entry: RemoteFileEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.icon)
                .foregroundColor(entry.isDirectory ? .accentColor : .secondary)
                .frame(width: 20)

            Text(entry.name)
                .lineLimit(1)

            Spacer()

            Text(entry.formattedSize)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)

            Text(entry.permissions)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }
}
