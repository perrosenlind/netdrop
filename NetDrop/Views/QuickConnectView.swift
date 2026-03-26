import SwiftUI

struct QuickConnectView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(\.dismiss) private var dismiss

    @State private var host: String = ""
    @State private var port: String = "22"
    @State private var username: String = "admin"
    @State private var passwordField: String = ""
    @State private var remotePath: String = "/"
    @State private var authType: AuthType = .password
    @State private var keyPath: String = "~/.ssh/id_rsa"
    @State private var saveAsFavorite: Bool = false
    @State private var favoriteName: String = ""

    private enum AuthType: String, CaseIterable {
        case password = "Password"
        case key = "SSH Key"
        case agent = "SSH Agent"
    }

    private var isValid: Bool {
        !host.isEmpty && !username.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "bolt.horizontal.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Quick Connect")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()

            Divider()

            Form {
                Section {
                    HStack(spacing: 8) {
                        TextField("Host / IP", text: $host)
                            .textFieldStyle(.roundedBorder)
                        Text(":")
                            .foregroundStyle(.secondary)
                        TextField("Port", text: $port)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                    }

                    TextField("Username", text: $username)

                    Picker("Auth", selection: $authType) {
                        ForEach(AuthType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    if authType == .password {
                        SecureField("Password", text: $passwordField)
                    }

                    if authType == .key {
                        TextField("Key Path", text: $keyPath)
                    }

                    TextField("Remote Path", text: $remotePath)
                }

                Section {
                    Toggle("Save as favorite", isOn: $saveAsFavorite)
                    if saveAsFavorite {
                        TextField("Name", text: $favoriteName, prompt: Text(host))
                    }
                }
            }
            .formStyle(.grouped)
            .frame(width: 400)

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Connect") { connect() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private func connect() {
        let authMethod: AuthMethod = switch authType {
        case .key: .key(path: keyPath)
        case .password: .password
        case .agent: .agent
        }

        let name = saveAsFavorite ? (favoriteName.isEmpty ? host : favoriteName) : host
        let favorite = Favorite(
            name: name,
            host: host,
            port: Int(port) ?? 22,
            username: username,
            authMethod: authMethod,
            remotePath: remotePath
        )

        if saveAsFavorite {
            favoritesStore.add(favorite)
        }

        // Store password in Keychain
        if authType == .password && !passwordField.isEmpty {
            KeychainService.savePassword(passwordField, for: favorite.id)
        }

        favoritesStore.selectedFavorite = favorite
        dismiss()
    }
}
