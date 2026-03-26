import SwiftUI
import UniformTypeIdentifiers

struct TransferView: View {
    @Environment(TransferManager.self) private var transferManager
    let favorite: Favorite

    @State private var localFilePath: String = ""
    @State private var remotePath: String = ""
    @State private var showingFilePicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Connection header
            HStack {
                Image(systemName: "network")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading) {
                    Text(favorite.name)
                        .font(.headline)
                    Text("\(favorite.username)@\(favorite.host):\(favorite.port)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            Divider()

            // Transfer form
            Form {
                Section("Upload File") {
                    HStack {
                        TextField("Local file", text: $localFilePath, prompt: Text("Select a file…"))
                            .textFieldStyle(.roundedBorder)
                        Button("Browse…") {
                            showingFilePicker = true
                        }
                    }

                    TextField("Remote path", text: $remotePath, prompt: Text(favorite.remotePath))
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button("Upload") {
                            startUpload()
                        }
                        .disabled(localFilePath.isEmpty)
                        .keyboardShortcut(.return, modifiers: .command)

                        Button("Download") {
                            startDownload()
                        }
                        .disabled(remotePath.isEmpty)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            // Active transfers
            TransferListView()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                localFilePath = url.path
            }
        }
        .onAppear {
            remotePath = favorite.remotePath
        }
    }

    private func startUpload() {
        let remote = remotePath.isEmpty ? favorite.remotePath : remotePath
        let fileName = (localFilePath as NSString).lastPathComponent
        let fullRemotePath = remote.hasSuffix("/") ? remote + fileName : remote + "/" + fileName
        transferManager.upload(
            localPath: localFilePath,
            remotePath: fullRemotePath,
            favorite: favorite
        )
        localFilePath = ""
    }

    private func startDownload() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = (remotePath as NSString).lastPathComponent
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            transferManager.download(
                remotePath: remotePath,
                localPath: url.path,
                favorite: favorite
            )
        }
    }
}
