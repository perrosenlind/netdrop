import SwiftUI
import UniformTypeIdentifiers

struct TransferView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(TransferManager.self) private var transferManager
    let favorite: Favorite

    @State private var localFilePaths: [String] = []
    @State private var remotePath: String = ""
    @State private var showingFilePicker = false
    @State private var isDragOver = false
    @State private var showBrowser = false

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
                Picker("", selection: $showBrowser) {
                    Label("Transfer", systemImage: "arrow.up.arrow.down").tag(false)
                    Label("Browse", systemImage: "folder").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Button {
                    favoritesStore.selectedFavorite = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .help("Close connection")
            }
            .padding()

            Divider()

            if showBrowser {
                RemoteFileBrowserView(favorite: favorite)
            } else {
                transferFormView
            }

            Divider()

            TransferListView()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                let newPaths = urls.map(\.path)
                for path in newPaths where !localFilePaths.contains(path) {
                    localFilePaths.append(path)
                }
            }
        }
        .onAppear {
            remotePath = favorite.remotePath
        }
    }

    private var transferFormView: some View {
        VStack(spacing: 0) {
            // Drop zone + file list
            VStack(spacing: 8) {
                if localFilePaths.isEmpty {
                    dropZone
                } else {
                    fileListView
                }
            }
            .padding()

            // Remote path + actions
            Form {
                Section {
                    TextField("Remote path", text: $remotePath, prompt: Text(favorite.remotePath))
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button("Add Files…") {
                            showingFilePicker = true
                        }

                        Spacer()

                        Button("Upload \(localFilePaths.count > 1 ? "\(localFilePaths.count) Files" : "")") {
                            startUpload()
                        }
                        .disabled(localFilePaths.isEmpty)
                        .keyboardShortcut(.return, modifiers: .command)
                        .buttonStyle(.borderedProminent)

                        Button("Download") {
                            startDownload()
                        }
                        .disabled(remotePath.isEmpty)
                    }
                }
            }
            .formStyle(.grouped)
        }
    }

    private var dropZone: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 36))
                .foregroundColor(isDragOver ? .accentColor : .secondary)
            Text("Drop files here or click Add Files")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isDragOver ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
        )
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers)
        }
    }

    private var fileListView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(localFilePaths.count) file(s) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear All") {
                    localFilePaths.removeAll()
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }

            List {
                ForEach(localFilePaths, id: \.self) { path in
                    HStack {
                        Image(systemName: "doc")
                        Text((path as NSString).lastPathComponent)
                        Spacer()
                        Button {
                            localFilePaths.removeAll { $0 == path }
                        } label: {
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .listStyle(.inset)
            .frame(minHeight: 80, maxHeight: 150)
            .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                handleDrop(providers)
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                DispatchQueue.main.async {
                    let path = url.path
                    if !localFilePaths.contains(path) {
                        localFilePaths.append(path)
                    }
                }
            }
        }
        return true
    }

    private func startUpload() {
        let remote = remotePath.isEmpty ? favorite.remotePath : remotePath
        transferManager.uploadMultiple(
            localPaths: localFilePaths,
            remotePath: remote,
            favorite: favorite
        )
        localFilePaths.removeAll()
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
