import Foundation

enum ConnectionStatus: Equatable {
    case testing
    case connected
    case failed(String)
}

struct ConnectionTester {
    /// Quick SSH connection test — runs `echo ok` on the remote host.
    static func test(favorite: Favorite) async -> ConnectionStatus {
        do {
            let result = try await runSSH(command: "echo ok", favorite: favorite)
            if result.exitCode == 0 && result.output.contains("ok") {
                return .connected
            } else {
                return .failed(friendlyError(from: result.output))
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    private static func runSSH(
        command: String,
        favorite: Favorite
    ) async throws -> (output: String, exitCode: Int32) {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")

            var args: [String] = []

            if favorite.port != 22 {
                args.append(contentsOf: ["-p", "\(favorite.port)"])
            }

            if case .key(let path) = favorite.authMethod {
                let expandedPath = (path as NSString).expandingTildeInPath
                args.append(contentsOf: ["-i", expandedPath])
            }

            args.append(contentsOf: ["-o", "StrictHostKeyChecking=no"])
            args.append(contentsOf: ["-o", "BatchMode=yes"])
            args.append(contentsOf: ["-o", "ConnectTimeout=5"])
            args.append("\(favorite.username)@\(favorite.host)")
            args.append(command)

            process.arguments = args

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

    static func friendlyError(from output: String) -> String {
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
            return "Host key verification failed — remove old key with ssh-keygen -R"
        }
        if lower.contains("permission denied") {
            return "Permission denied — check username and SSH key"
        }
        if lower.contains("could not resolve hostname") {
            return "Could not resolve hostname — check the address"
        }
        if lower.contains("network is unreachable") {
            return "Network is unreachable — check your connection"
        }

        // Trim to first meaningful line
        let lines = output.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return lines.first ?? "Unknown error"
    }
}
