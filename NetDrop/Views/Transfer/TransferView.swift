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
    @State private var connectionStatus: ConnectionStatus = .testing
    @State private var reconnectTimer: Timer?
    @State private var showingPasswordPrompt = false
    @State private var passwordField: String = ""
    @State private var showingSavePrompt = false
    @State private var saveName: String = ""
    @State private var saveGroup: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Connection header
            HStack(spacing: 10) {
                // Status indicator
                Group {
                    switch connectionStatus {
                    case .testing:
                        ProgressView()
                            .controlSize(.small)
                    case .connected:
                        Image(systemName: "circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    case .failed:
                        Image(systemName: "circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .frame(width: 16)

                VStack(alignment: .leading) {
                    HStack(spacing: 6) {
                        Text(favorite.name)
                            .font(.headline)
                        statusBadge
                    }
                    Text("\(favorite.username)@\(favorite.host):\(favorite.port)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if case .failed(let message) = connectionStatus {
                        Text(message)
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if case .failed = connectionStatus {
                    Button("Retry") {
                        testConnection()
                    }
                    .controlSize(.small)
                }

                if !favoritesStore.favorites.contains(where: { $0.id == favorite.id }) {
                    Button {
                        saveName = favorite.name
                        showingSavePrompt = true
                    } label: {
                        Label("Save", systemImage: "star")
                    }
                    .controlSize(.small)
                }

                Picker("", selection: $showBrowser) {
                    Label("Transfer", systemImage: "arrow.up.arrow.down").tag(false)
                    Label("Browse", systemImage: "folder").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Button {
                    favoritesStore.selectedFavorite = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Disconnect")
                    }
                    .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .help("Disconnect (Cmd+W)")
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
            testConnection()
            startReconnectTimer()
        }
        .onDisappear {
            reconnectTimer?.invalidate()
            reconnectTimer = nil
        }
        .onChange(of: favorite) { _, _ in
            testConnection()
        }
        .sheet(isPresented: $showingPasswordPrompt) {
            PasswordPromptView(
                favoriteName: favorite.name,
                password: $passwordField
            ) {
                // Save to Keychain and retry
                KeychainService.savePassword(passwordField, for: favorite.id)
                passwordField = ""
                testConnection()
            } onCancel: {
                passwordField = ""
            }
        }
        .sheet(isPresented: $showingSavePrompt) {
            SaveFavoriteView(
                favorite: favorite,
                name: $saveName,
                group: $saveGroup
            ) {
                var fav = favorite
                fav.name = saveName.isEmpty ? favorite.host : saveName
                fav.group = saveGroup
                favoritesStore.add(fav)
                favoritesStore.selectedFavorite = fav
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch connectionStatus {
        case .testing:
            Text("Connecting…")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.yellow.opacity(0.2))
                .foregroundStyle(.yellow)
                .clipShape(Capsule())
        case .connected:
            Text("Connected")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.green.opacity(0.2))
                .foregroundStyle(.green)
                .clipShape(Capsule())
        case .failed:
            Text("Offline")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.red.opacity(0.2))
                .foregroundStyle(.red)
                .clipShape(Capsule())
        }
    }

    private func testConnection() {
        connectionStatus = .testing
        Task {
            let result = await ConnectionTester.test(favorite: favorite)
            await MainActor.run {
                connectionStatus = result
                // If password auth failed and Keychain is empty, prompt for password
                if case .failed(let msg) = result,
                   case .password = favorite.authMethod,
                   msg.lowercased().contains("permission denied"),
                   favorite.password == nil || favorite.password?.isEmpty == true {
                    showingPasswordPrompt = true
                }
            }
        }
    }

    private func startReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            // Only auto-retry when offline
            if case .failed = connectionStatus {
                testConnection()
            }
        }
    }

    private var transferFormView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                if localFilePaths.isEmpty {
                    dropZone
                } else {
                    fileListView
                }
            }
            .padding()

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
