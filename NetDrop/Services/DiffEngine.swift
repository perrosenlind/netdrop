import Foundation

struct DiffLine: Identifiable {
    let id = UUID()
    let leftLineNumber: Int?
    let rightLineNumber: Int?
    let leftText: String?
    let rightText: String?
    let type: DiffLineType
}

enum DiffLineType {
    case unchanged
    case added
    case removed
    case modified
}

struct DiffEngine {
    /// Compute a side-by-side diff of two texts
    static func diff(left: String, right: String) -> [DiffLine] {
        let leftLines = left.components(separatedBy: .newlines)
        let rightLines = right.components(separatedBy: .newlines)

        // Simple LCS-based diff
        let lcs = longestCommonSubsequence(leftLines, rightLines)
        var result: [DiffLine] = []

        var li = 0, ri = 0, ci = 0

        while li < leftLines.count || ri < rightLines.count {
            if ci < lcs.count && li < leftLines.count && ri < rightLines.count
                && leftLines[li] == lcs[ci] && rightLines[ri] == lcs[ci] {
                // Unchanged line
                result.append(DiffLine(
                    leftLineNumber: li + 1,
                    rightLineNumber: ri + 1,
                    leftText: leftLines[li],
                    rightText: rightLines[ri],
                    type: .unchanged
                ))
                li += 1; ri += 1; ci += 1
            } else if ci < lcs.count && li < leftLines.count && leftLines[li] != lcs[ci] {
                if ri < rightLines.count && rightLines[ri] != (ci < lcs.count ? lcs[ci] : "") {
                    // Modified line
                    result.append(DiffLine(
                        leftLineNumber: li + 1,
                        rightLineNumber: ri + 1,
                        leftText: leftLines[li],
                        rightText: rightLines[ri],
                        type: .modified
                    ))
                    li += 1; ri += 1
                } else {
                    // Removed from left
                    result.append(DiffLine(
                        leftLineNumber: li + 1,
                        rightLineNumber: nil,
                        leftText: leftLines[li],
                        rightText: nil,
                        type: .removed
                    ))
                    li += 1
                }
            } else if ri < rightLines.count {
                // Added on right
                result.append(DiffLine(
                    leftLineNumber: nil,
                    rightLineNumber: ri + 1,
                    leftText: nil,
                    rightText: rightLines[ri],
                    type: .added
                ))
                ri += 1
            } else if li < leftLines.count {
                result.append(DiffLine(
                    leftLineNumber: li + 1,
                    rightLineNumber: nil,
                    leftText: leftLines[li],
                    rightText: nil,
                    type: .removed
                ))
                li += 1
            }
        }

        return result
    }

    /// Summary stats
    static func summary(of lines: [DiffLine]) -> (added: Int, removed: Int, modified: Int, unchanged: Int) {
        var a = 0, r = 0, m = 0, u = 0
        for line in lines {
            switch line.type {
            case .added: a += 1
            case .removed: r += 1
            case .modified: m += 1
            case .unchanged: u += 1
            }
        }
        return (a, r, m, u)
    }

    private static func longestCommonSubsequence(_ a: [String], _ b: [String]) -> [String] {
        let m = a.count, n = b.count
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 1...m {
            for j in 1...n {
                if a[i-1] == b[j-1] {
                    dp[i][j] = dp[i-1][j-1] + 1
                } else {
                    dp[i][j] = max(dp[i-1][j], dp[i][j-1])
                }
            }
        }

        var result: [String] = []
        var i = m, j = n
        while i > 0 && j > 0 {
            if a[i-1] == b[j-1] {
                result.append(a[i-1])
                i -= 1; j -= 1
            } else if dp[i-1][j] > dp[i][j-1] {
                i -= 1
            } else {
                j -= 1
            }
        }

        return result.reversed()
    }
}
