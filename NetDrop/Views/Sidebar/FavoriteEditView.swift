import SwiftUI

enum FavoriteEditMode: Identifiable {
    case add
    case edit(Favorite)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let fav): return fav.id.uuidString
        }
    }
}

struct FavoriteEditView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(\.dismiss) private var dismiss

    let mode: FavoriteEditMode

    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = "22"
    @State private var username: String = "admin"
    @State private var authType: AuthType = .key
    @State private var keyPath: String = "~/.ssh/id_rsa"
    @State private var showKeyPicker = false
    @State private var remotePath: String = "/"
    @State private var group: String = ""

    private enum AuthType: String, CaseIterable {
        case key = "SSH Key"
        case password = "Password"
        case agent = "SSH Agent"
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var title: String {
        isEditing ? "Edit Connection" : "New Connection"
    }

    private var isValid: Bool {
        !name.isEmpty && !host.isEmpty && !username.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Connection") {
                    TextField("Name", text: $name)
                    TextField("Host / IP", text: $host)
                    TextField("Port", text: $port)
                    TextField("Username", text: $username)
                }

                Section("Authentication") {
                    Picker("Method", selection: $authType) {
                        ForEach(AuthType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    if authType == .key {
                        HStack {
                            TextField("Key Path", text: $keyPath)
                            Button("Browse…") {
                                showKeyPicker = true
                            }
                        }
                    }
                }

                Section("Options") {
                    TextField("Remote Path", text: $remotePath)
                    TextField("Group", text: $group, prompt: Text("Optional"))
                    if !favoritesStore.groups.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(favoritesStore.groups, id: \.self) { g in
                                Button(g) { group = g }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .frame(width: 420)

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isEditing ? "Save" : "Add") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding()
        }
        .fileImporter(
            isPresented: $showKeyPicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                keyPath = url.path
            }
        }
        .onAppear {
            if case .edit(let favorite) = mode {
                populateFields(from: favorite)
            }
        }
    }

    private func populateFields(from favorite: Favorite) {
        name = favorite.name
        host = favorite.host
        port = "\(favorite.port)"
        username = favorite.username
        remotePath = favorite.remotePath
        group = favorite.group

        switch favorite.authMethod {
        case .password:
            authType = .password
        case .key(let path):
            authType = .key
            keyPath = path
        case .agent:
            authType = .agent
        }
    }

    private func save() {
        let authMethod: AuthMethod = switch authType {
        case .key: .key(path: keyPath)
        case .password: .password
        case .agent: .agent
        }

        var favorite: Favorite
        if case .edit(let existing) = mode {
            favorite = existing
        } else {
            favorite = Favorite()
        }

        favorite.name = name
        favorite.host = host
        favorite.port = Int(port) ?? 22
        favorite.username = username
        favorite.authMethod = authMethod
        favorite.remotePath = remotePath
        favorite.group = group

        if isEditing {
            favoritesStore.update(favorite)
        } else {
            favoritesStore.add(favorite)
        }

        dismiss()
    }
}
