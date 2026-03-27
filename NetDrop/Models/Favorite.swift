import Foundation

struct Favorite: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var authMethod: AuthMethod
    var remotePath: String
    var group: String

    init(
        id: UUID = UUID(),
        name: String = "",
        host: String = "",
        port: Int = 22,
        username: String = "admin",
        authMethod: AuthMethod = .password,
        remotePath: String = "/",
        group: String = ""
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.remotePath = remotePath
        self.group = group
    }

    /// Get stored password from Keychain (only for .password auth)
    var password: String? {
        KeychainService.getPassword(for: id)
    }
}

enum AuthMethod: Codable, Hashable {
    case password
    case key(path: String)
    case agent
}
