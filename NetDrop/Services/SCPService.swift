import Foundation

struct SCPService {
    /// Upload a local file to a remote host via scp
    static func upload(
        localPath: String,
        remotePath: String,
        favorite: Favorite
    ) async throws -> (output: String, exitCode: Int32) {
        let remoteTarget = "\(favorite.username)@\(favorite.host):\(remotePath)"
        var args = buildBaseArgs(favorite: favorite)
        args.append(localPath)
        args.append(remoteTarget)
        return try await runSCP(args: args)
    }

    /// Download a remote file to a local path via scp
    static func download(
        remotePath: String,
        localPath: String,
        favorite: Favorite
    ) async throws -> (output: String, exitCode: Int32) {
        let remoteTarget = "\(favorite.username)@\(favorite.host):\(remotePath)"
        var args = buildBaseArgs(favorite: favorite)
        args.append(remoteTarget)
        args.append(localPath)
        return try await runSCP(args: args)
    }

    private static func buildBaseArgs(favorite: Favorite) -> [String] {
        var args: [String] = []

        // Port
        if favorite.port != 22 {
            args.append(contentsOf: ["-P", "\(favorite.port)"])
        }

        // Key-based auth
        if case .key(let path) = favorite.authMethod {
            let expandedPath = (path as NSString).expandingTildeInPath
            args.append(contentsOf: ["-i", expandedPath])
        }

        // Disable strict host key checking for network devices (common in lab environments)
        args.append(contentsOf: ["-o", "StrictHostKeyChecking=no"])

        // Verbose output for progress parsing
        args.append("-v")

        return args
    }

    private static func runSCP(args: [String]) async throws -> (output: String, exitCode: Int32) {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/scp")
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
}
