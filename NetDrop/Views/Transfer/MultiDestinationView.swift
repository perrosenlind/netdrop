import SwiftUI
import UniformTypeIdentifiers

struct MultiDestinationView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(TransferManager.self) private var transferManager
    @Environment(\.dismiss) private var dismiss

    enum PickerMode { case files, ipList }

    @State private var selectedFavoriteIDs: Set<UUID> = []
    @State private var localPaths: [String] = []
    @State private var pickerMode: PickerMode = .files
    @State private var showingPicker = false
    @State private var importedHosts: [AdHocHost] = []
    @State private var selectedImportedIDs: Set<UUID> = []
    @State private var importUsername: String = "admin"
    @State private var importPassword: String = ""
    @State private var importAuthMethod: ImportAuthType = .agent
    @State private var importKeyPath: String = "~/.ssh/id_rsa"
    @State private var importRemotePath: String = "/"

    private enum ImportAuthType: String, CaseIterable {
        case password = "Password"
        case key = "SSH Key"
        case agent = "SSH Agent"
    }

    /// Temporary host parsed from an IP list (not saved as a favorite)
    struct AdHocHost: Identifiable, Hashable {
        let id = UUID()
        let address: String
    }

    private var totalDestinations: Int {
        selectedFavoriteIDs.count + selectedImportedIDs.count
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "arrow.up.to.line.compact")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Upload to Multiple Devices")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()

            Divider()

            HStack(spacing: 0) {
                // Left: file selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Files")
                        .font(.headline)

                    if localPaths.isEmpty {
                        ContentUnavailableView {
                            Label("No Files", systemImage: "doc")
                        } description: {
                            Text("Add files to upload.")
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(localPaths, id: \.self) { path in
                                HStack {
                                    Image(systemName: "doc")
                                    Text((path as NSString).lastPathComponent)
                                    Spacer()
                                    Text((path as NSString).deletingLastPathComponent)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .onDelete { offsets in
                                localPaths.remove(atOffsets: offsets)
                            }
                        }
                        .listStyle(.inset)
                    }

                    Button("Add Files…") {
                        pickerMode = .files
                        showingPicker = true
                    }
                }
                .padding()
                .frame(minWidth: 250)

                Divider()

                // Right: destination selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Destinations")
                        .font(.headline)

                    List {
                        // Saved favorites
                        if !favoritesStore.favorites.isEmpty {
                            Section("Favorites") {
                                ForEach(favoritesStore.favorites) { fav in
                                    HStack {
                                        Image(systemName: selectedFavoriteIDs.contains(fav.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedFavoriteIDs.contains(fav.id) ? .accentColor : .secondary)
                                        FavoriteRow(favorite: fav)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if selectedFavoriteIDs.contains(fav.id) {
                                            selectedFavoriteIDs.remove(fav.id)
                                        } else {
                                            selectedFavoriteIDs.insert(fav.id)
                                        }
                                    }
                                }
                            }
                        }

                        // Imported IPs
                        if !importedHosts.isEmpty {
                            Section("Imported IPs (\(importedHosts.count))") {
                                ForEach(importedHosts) { host in
                                    HStack {
                                        Image(systemName: selectedImportedIDs.contains(host.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedImportedIDs.contains(host.id) ? .accentColor : .secondary)
                                        Image(systemName: "network")
                                            .foregroundStyle(.secondary)
                                        Text(host.address)
                                            .font(.system(.body, design: .monospaced))
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if selectedImportedIDs.contains(host.id) {
                                            selectedImportedIDs.remove(host.id)
                                        } else {
                                            selectedImportedIDs.insert(host.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.inset)

                    // Import IP settings
                    if !importedHosts.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Imported IP Settings")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                Text("User:")
                                    .font(.caption)
                                TextField("admin", text: $importUsername)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                Text("Path:")
                                    .font(.caption)
                                TextField("/", text: $importRemotePath)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                            }

                            HStack(spacing: 8) {
                                Text("Auth:")
                                    .font(.caption)
                                Picker("", selection: $importAuthMethod) {
                                    ForEach(ImportAuthType.allCases, id: \.self) { t in
                                        Text(t.rawValue).tag(t)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 100)

                                if importAuthMethod == .password {
                                    SecureField("Password", text: $importPassword)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 120)
                                }

                                if importAuthMethod == .key {
                                    TextField("~/.ssh/id_rsa", text: $importKeyPath)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 120)
                                }
                            }
                        }
                    }

                    HStack {
                        Button("Select All") {
                            selectedFavoriteIDs = Set(favoritesStore.favorites.map(\.id))
                            selectedImportedIDs = Set(importedHosts.map(\.id))
                        }
                        Button("Clear") {
                            selectedFavoriteIDs.removeAll()
                            selectedImportedIDs.removeAll()
                        }
                        Spacer()
                        Button("Import IPs…") {
                            pickerMode = .ipList
                            showingPicker = true
                        }
                    }
                }
                .padding()
                .frame(minWidth: 280)
            }

            Divider()

            HStack {
                Text("\(localPaths.count) file(s) → \(totalDestinations) device(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Upload All") { startMultiUpload() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(localPaths.isEmpty || totalDestinations == 0)
            }
            .padding()
        }
        .frame(width: 680, height: 500)
        .fileImporter(
            isPresented: $showingPicker,
            allowedContentTypes: pickerMode == .files ? [.item] : [.text, .plainText, .commaSeparatedText, .data],
            allowsMultipleSelection: pickerMode == .files
        ) { result in
            guard case .success(let urls) = result else { return }
            switch pickerMode {
            case .files:
                for url in urls where !localPaths.contains(url.path) {
                    localPaths.append(url.path)
                }
            case .ipList:
                if let url = urls.first {
                    importIPList(from: url)
                }
            }
        }
    }

    private func importIPList(from url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }

        let existingAddresses = Set(importedHosts.map(\.address))
        let addresses = IPListParser.parse(content)

        for address in addresses where !existingAddresses.contains(address) {
            let host = AdHocHost(address: address)
            importedHosts.append(host)
            selectedImportedIDs.insert(host.id)
        }
    }

    private func startMultiUpload() {
        // Gather saved favorites
        var allFavorites = favoritesStore.favorites.filter { selectedFavoriteIDs.contains($0.id) }

        // Create ad-hoc favorites for imported IPs
        let authMethod: AuthMethod = switch importAuthMethod {
        case .password: .password
        case .key: .key(path: importKeyPath)
        case .agent: .agent
        }

        for host in importedHosts where selectedImportedIDs.contains(host.id) {
            let fav = Favorite(
                name: host.address,
                host: host.address,
                username: importUsername,
                authMethod: authMethod,
                remotePath: importRemotePath
            )
            // Store password in Keychain for this ad-hoc favorite
            if importAuthMethod == .password && !importPassword.isEmpty {
                KeychainService.savePassword(importPassword, for: fav.id)
            }
            allFavorites.append(fav)
        }

        transferManager.uploadToMultipleDestinations(localPaths: localPaths, favorites: allFavorites)
        dismiss()
    }
}
