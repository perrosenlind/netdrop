import Foundation

struct SCPService {
    /// Upload a local file to a remote host via scp with progress callback
    static func upload(
        localPath: String,
        remotePath: String,
        favorite: Favorite,
        onProgress: (@Sendable (String) -> Void)? = nil
    ) async throws -> (output: String, exitCode: Int32) {
        let remoteTarget = "\(favorite.username)@\(favorite.host):\(remotePath)"
        var args = buildBaseArgs(favorite: favorite)
        args.append(localPath)
        args.append(remoteTarget)
        return try await runSCP(args: args, onProgress: onProgress)
    }

    /// Download a remote file to a local path via scp with progress callback
    static func download(
        remotePath: String,
        localPath: String,
        favorite: Favorite,
        onProgress: (@Sendable (String) -> Void)? = nil
    ) async throws -> (output: String, exitCode: Int32) {
        let remoteTarget = "\(favorite.username)@\(favorite.host):\(remotePath)"
        var args = buildBaseArgs(favorite: favorite)
        args.append(remoteTarget)
        args.append(localPath)
        return try await runSCP(args: args, onProgress: onProgress)
    }

    private static func buildBaseArgs(favorite: Favorite) -> [String] {
        var args: [String] = []

        if favorite.port != 22 {
            args.append(contentsOf: ["-P", "\(favorite.port)"])
        }

        if case .key(let path) = favorite.authMethod {
            let expandedPath = (path as NSString).expandingTildeInPath
            args.append(contentsOf: ["-i", expandedPath])
        }

        args.append(contentsOf: ["-o", "StrictHostKeyChecking=no"])

        return args
    }

    private static func runSCP(
        args: [String],
        onProgress: (@Sendable (String) -> Void)? = nil
    ) async throws -> (output: String, exitCode: Int32) {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/scp")
            process.arguments = args

            let pipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = pipe
            process.standardError = errorPipe

            // Stream stderr for progress parsing
            if let onProgress {
                errorPipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else { return }
                    // SCP progress lines look like: filename  45%  1.2MB  00:03
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
