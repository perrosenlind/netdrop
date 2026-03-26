import Foundation

enum ConnectionStatus: Equatable {
    case testing
    case connected
    case failed(String)
}

struct ConnectionTester {
    private static let sshpassPath = "/opt/homebrew/bin/sshpass"

    /// Quick SSH connection test — runs `echo ok` on the remote host.
    static func test(favorite: Favorite, password: String? = nil) async -> ConnectionStatus {
        do {
            let result = try await runSSH(command: "echo ok", favorite: favorite, password: password)
            if result.exitCode == 0 && result.output.contains("ok") {
                return .connected
            } else {
                return .failed(friendlyError(from: result.output, authMethod: favorite.authMethod))
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    private static func runSSH(
        command: String,
        favorite: Favorite,
        password: String? = nil
    ) async throws -> (output: String, exitCode: Int32) {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()

            var sshArgs: [String] = []

            if favorite.port != 22 {
                sshArgs.append(contentsOf: ["-p", "\(favorite.port)"])
            }

            if case .key(let path) = favorite.authMethod {
                let expandedPath = (path as NSString).expandingTildeInPath
                sshArgs.append(contentsOf: ["-i", expandedPath])
            }

            sshArgs.append(contentsOf: ["-o", "StrictHostKeyChecking=no"])
            sshArgs.append(contentsOf: ["-o", "ConnectTimeout=5"])

            if case .password = favorite.authMethod {
                // no BatchMode for password
            } else {
                sshArgs.append(contentsOf: ["-o", "BatchMode=yes"])
            }

            sshArgs.append("\(favorite.username)@\(favorite.host)")
            sshArgs.append(command)

            // Use sshpass for password auth
            let pw = password ?? favorite.password
            if case .password = favorite.authMethod, let pw, !pw.isEmpty {
                process.executableURL = URL(fileURLWithPath: sshpassPath)
                process.arguments = ["-p", pw, "/usr/bin/ssh"] + sshArgs
            } else {
                process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
                process.arguments = sshArgs
            }

            let pipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = pipe
            process.standardError = errorPipe

            process.terminationHandler = { proc in
                let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8) ?? ""
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                let combined = output + errorOutput

                continuation.resume(returning: (output: combined, exitCode: proc.terminationStatus))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    static func friendlyError(from output: String, authMethod: AuthMethod = .agent) -> String {
        let lower = output.lowercased()

        if lower.contains("connection refused") {
            return "Connection refused — SSH is not running on this host"
        }
        if lower.contains("connection timed out") || lower.contains("operation timed out") {
            return "Connection timed out — host is unreachable"
        }
        if lower.contains("no route to host") {
            return "No route to host — check the IP address"
        }
        if lower.contains("host key verification failed") {
            return "Host key changed — run: ssh-keygen -R <host>"
        }
        if lower.contains("permission denied") {
            switch authMethod {
            case .password:
                return "Permission denied — check username and password"
            case .key(let path):
                return "Permission denied — check key at \(path)"
            case .agent:
                return "Permission denied — no key found in SSH agent"
            }
        }
        if lower.contains("could not resolve hostname") {
            return "Could not resolve hostname — check the address"
        }
        if lower.contains("network is unreachable") {
            return "Network is unreachable — check your connection"
        }

        let lines = output.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("debug") }
        return lines.last ?? "Connection failed"
    }
}
