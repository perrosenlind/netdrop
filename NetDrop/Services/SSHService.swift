import Foundation

struct SSHService {
    /// List remote directory contents via SSH
    static func listDirectory(
        path: String,
        favorite: Favorite
    ) async throws -> [RemoteFileEntry] {
        let command = "ls -la \(path)"
        let result = try await runSSH(command: command, favorite: favorite)

        guard result.exitCode == 0 else {
            throw SSHError.commandFailed(result.output)
        }

        return parseLsOutput(result.output, directory: path)
    }

    /// Create a remote directory
    static func mkdir(
        path: String,
        favorite: Favorite
    ) async throws {
        let result = try await runSSH(command: "mkdir -p \(path)", favorite: favorite)
        guard result.exitCode == 0 else {
            throw SSHError.commandFailed(result.output)
        }
    }

    /// Delete a remote file
    static func remove(
        path: String,
        favorite: Favorite
    ) async throws {
        let result = try await runSSH(command: "rm -f \(path)", favorite: favorite)
        guard result.exitCode == 0 else {
            throw SSHError.commandFailed(result.output)
        }
    }

    /// Rename a remote file
    static func rename(
        from oldPath: String,
        to newPath: String,
        favorite: Favorite
    ) async throws {
        let result = try await runSSH(command: "mv \(oldPath) \(newPath)", favorite: favorite)
        guard result.exitCode == 0 else {
            throw SSHError.commandFailed(result.output)
        }
    }

    private static let sshpassPath = "/opt/homebrew/bin/sshpass"

    private static func runSSH(
        command: String,
        favorite: Favorite
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
            sshArgs.append(contentsOf: ["-o", "ConnectTimeout=10"])

            if case .password = favorite.authMethod {
                // no BatchMode
            } else {
                sshArgs.append(contentsOf: ["-o", "BatchMode=yes"])
            }

            sshArgs.append("\(favorite.username)@\(favorite.host)")
            sshArgs.append(command)

            if case .password = favorite.authMethod, let pw = favorite.password, !pw.isEmpty {
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
                let combined = output.isEmpty ? errorOutput : output

                continuation.resume(returning: (output: combined, exitCode: proc.terminationStatus))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private static func parseLsOutput(_ output: String, directory: String) -> [RemoteFileEntry] {
        var entries: [RemoteFileEntry] = []
        let lines = output.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("total") else { continue }

            // Parse ls -la output: permissions links owner group size month day time/year name
            let parts = trimmed.split(separator: " ", maxSplits: 8, omittingEmptySubsequences: true)
            guard parts.count >= 9 else { continue }

            let permissions = String(parts[0])
            let name = String(parts[8])

            guard name != "." && name != ".." else { continue }

            let isDirectory = permissions.hasPrefix("d")
            let isLink = permissions.hasPrefix("l")
            let size = Int64(parts[4]) ?? 0

            let path = directory.hasSuffix("/") ? directory + name : directory + "/" + name

            entries.append(RemoteFileEntry(
                name: name,
                path: path,
                isDirectory: isDirectory,
                isSymlink: isLink,
                size: size,
                permissions: permissions
            ))
        }

        return entries.sorted { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
}

enum SSHError: LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let output): return output
        }
    }
}
