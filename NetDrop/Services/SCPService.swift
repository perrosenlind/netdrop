import Foundation

struct SCPService {
    private static let sshpassPath = "/opt/homebrew/bin/sshpass"

    static func upload(
        localPath: String,
        remotePath: String,
        favorite: Favorite,
        password: String? = nil,
        legacySCP: Bool = false,
        onProgress: (@Sendable (String) -> Void)? = nil
    ) async throws -> (output: String, exitCode: Int32) {
        let remoteTarget = "\(favorite.username)@\(favorite.host):\(remotePath)"
        var args = buildBaseArgs(favorite: favorite, legacySCP: legacySCP)
        args.append(localPath)
        args.append(remoteTarget)

        let pw = password ?? favorite.password
        return try await runSCP(args: args, password: pw, favorite: favorite, onProgress: onProgress)
    }

    static func download(
        remotePath: String,
        localPath: String,
        favorite: Favorite,
        password: String? = nil,
        legacySCP: Bool = false,
        onProgress: (@Sendable (String) -> Void)? = nil
    ) async throws -> (output: String, exitCode: Int32) {
        let remoteTarget = "\(favorite.username)@\(favorite.host):\(remotePath)"
        var args = buildBaseArgs(favorite: favorite, legacySCP: legacySCP)
        args.append(remoteTarget)
        args.append(localPath)

        let pw = password ?? favorite.password
        return try await runSCP(args: args, password: pw, favorite: favorite, onProgress: onProgress)
    }

    private static func buildBaseArgs(favorite: Favorite, legacySCP: Bool = false) -> [String] {
        var args: [String] = []

        // Force legacy SCP protocol (required for FortiGate, OpenSSH 9.0+)
        if legacySCP {
            args.append("-O")
        }

        if favorite.port != 22 {
            args.append(contentsOf: ["-P", "\(favorite.port)"])
        }

        if case .key(let path) = favorite.authMethod {
            let expandedPath = (path as NSString).expandingTildeInPath
            args.append(contentsOf: ["-i", expandedPath])
        }

        args.append(contentsOf: ["-o", "StrictHostKeyChecking=no"])
        args.append(contentsOf: ["-o", "ConnectTimeout=10"])

        // Prevent hanging on password prompt for key/agent auth
        if case .password = favorite.authMethod {
            // no BatchMode for password
        } else {
            args.append(contentsOf: ["-o", "BatchMode=yes"])
        }

        return args
    }

    private static func runSCP(
        args: [String],
        password: String?,
        favorite: Favorite,
        onProgress: (@Sendable (String) -> Void)? = nil
    ) async throws -> (output: String, exitCode: Int32) {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()

            // Use sshpass for password auth
            if case .password = favorite.authMethod, let pw = password, !pw.isEmpty {
                process.executableURL = URL(fileURLWithPath: sshpassPath)
                process.arguments = ["-p", pw, "/usr/bin/scp"] + args
            } else {
                process.executableURL = URL(fileURLWithPath: "/usr/bin/scp")
                process.arguments = args
            }

            let pipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = pipe
            process.standardError = errorPipe

            if let onProgress {
                errorPipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else { return }
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.contains("%") {
                        onProgress(trimmed)
                    }
                }
            }

            process.terminationHandler = { proc in
                errorPipe.fileHandleForReading.readabilityHandler = nil
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
}
