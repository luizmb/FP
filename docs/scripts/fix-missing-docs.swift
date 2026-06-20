#!/usr/bin/env swift
// SPDX-License-Identifier: Apache-2.0
//
// Fixes `missing_docs` SwiftLint violations.
// Adds `///` doc comments to undocumented public declarations.
//
// Strategy:
//   1. If a non-MARK `// ` comment precedes the declaration, converts it to `/// `.
//   2. Otherwise generates a minimal doc from the operator name and MARK section.
//   3. For @available-annotated declarations, places docs above the @available.
//
// Usage: swift docs/scripts/fix-missing-docs.swift
// Run from the repo root. Requires `mint` on PATH.

import Foundation

// MARK: - Shell

func swiftlintOutput() -> String {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    proc.arguments = ["mint", "run", "swiftlint", "lint", "--strict"]
    let pipe = Pipe()
    proc.standardOutput = pipe
    proc.standardError = pipe
    try? proc.run()
    proc.waitUntilExit()
    return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
}

// MARK: - Violation parsing

func getViolations() -> [String: Set<Int>] {
    let output = swiftlintOutput()
    var result: [String: Set<Int>] = [:]
    for line in output.components(separatedBy: "\n") {
        guard line.contains("missing_docs") else { continue }
        let parts = line.components(separatedBy: ":")
        guard parts.count >= 2, let lineno = Int(parts[1]) else { continue }
        result[parts[0], default: []].insert(lineno)
    }
    return result
}

// MARK: - Doc generation helpers

func findMARKSection(in lines: [String], before idx: Int) -> String? {
    for i in stride(from: idx - 1, through: 0, by: -1) {
        let s = lines[i].trimmingCharacters(in: .whitespaces)
        if let m = s.range(of: #"^//\s*MARK:\s*[-–]\s*(.+)$"#, options: .regularExpression) {
            let content = String(s[m]).components(separatedBy: CharacterSet(charactersIn: "–-")).dropFirst().joined(separator: "-")
            return content.trimmingCharacters(in: .whitespaces)
        }
    }
    return nil
}

func extractOperatorName(from line: String) -> String? {
    // Match: [optional @attr] public func NAME
    let pattern = #"(?:public|internal)\s+func\s+(`[^`]+`|[^\s(]+)"#
    guard let range = line.range(of: pattern, options: .regularExpression) else { return nil }
    let match = String(line[range])
    // Extract NAME (last component)
    let parts = match.components(separatedBy: .whitespaces)
    return parts.last.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "`")) }
}

func isOperatorName(_ name: String) -> Bool {
    let alphanumeric = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
    return !name.unicodeScalars.allSatisfy { alphanumeric.contains($0) }
}

func generateDoc(for line: String, in lines: [String], at idx: Int, indent: String) -> String {
    let mark = findMARKSection(in: lines, before: idx)
    let markSuffix = mark.map { " for `\($0)`" } ?? ""

    if let op = extractOperatorName(from: line) {
        if isOperatorName(op) {
            return "\(indent)/// `\(op)` overload\(markSuffix)."
        } else {
            return "\(indent)/// `\(op)`\(markSuffix)."
        }
    }

    // Property
    if let propMatch = line.range(of: #"(?:var|let)\s+(\w+)"#, options: .regularExpression) {
        let parts = String(line[propMatch]).components(separatedBy: .whitespaces)
        if let name = parts.last { return "\(indent)/// The `\(name)` property." }
    }

    // Type
    if let typeMatch = line.range(of: #"(?:struct|class|enum|protocol|actor)\s+(\w+)"#, options: .regularExpression) {
        let parts = String(line[typeMatch]).components(separatedBy: .whitespaces)
        if let name = parts.last { return "\(indent)/// `\(name)`\(markSuffix)." }
    }

    if line.contains("typealias") { return "\(indent)/// Type alias\(markSuffix)." }
    if line.contains(" init") { return "\(indent)/// Initializer\(markSuffix)." }
    if line.contains("subscript") { return "\(indent)/// Subscript\(markSuffix)." }
    return "\(indent)/// Declaration\(markSuffix)."
}

// MARK: - Attribute skipping

/// Returns the index at which to insert the doc comment (above @available etc.).
func insertPosition(in lines: [String], before idx: Int) -> Int {
    var i = idx - 1
    while i >= 0 {
        let s = lines[i].trimmingCharacters(in: .whitespaces)
        guard s.hasPrefix("@") else { break }
        i -= 1
    }
    return i + 1
}

// MARK: - Comment conversion

/// Checks if lines immediately before `before` (ignoring blanks) are non-MARK // comments.
func precedingPlainComment(in lines: [String], before idx: Int) -> (start: Int, end: Int)? {
    var i = idx - 1
    while i >= 0, lines[i].trimmingCharacters(in: .whitespaces).isEmpty {
        i -= 1
    }
    var end = i
    var start = i
    while start >= 0 {
        let s = lines[start].trimmingCharacters(in: .whitespaces)
        guard s.hasPrefix("//"), !s.hasPrefix("// MARK:"), !s.hasPrefix("// swiftlint") else { break }
        start -= 1
    }
    start += 1
    return (start <= end) ? (start, end) : nil
}

// MARK: - File processing

func fixFile(_ filepath: String, violatingLines: Set<Int>) -> Int {
    guard let content = try? String(contentsOfFile: filepath, encoding: .utf8) else { return 0 }
    var lines = content.components(separatedBy: "\n").map { $0 + "\n" }
    if lines.last == "\n", content.hasSuffix("\n") { lines.removeLast() }

    var result = lines
    var offset = 0
    var fixed = 0

    for origLine in violatingLines.sorted() {
        let idx = origLine - 1 + offset
        guard idx < result.count else { continue }
        let line = result[idx]
        let leading = line.prefix(while: { $0 == " " }).count
        let indent = String(repeating: " ", count: leading)

        // Find insertion position (above @available)
        let insertAt = insertPosition(in: result, before: idx)

        // Check if there's already a doc comment just before insertAt
        var checkIdx = insertAt - 1
        while checkIdx >= 0, result[checkIdx].trimmingCharacters(in: .whitespaces).isEmpty {
            checkIdx -= 1
        }
        if checkIdx >= 0, result[checkIdx].trimmingCharacters(in: .whitespaces).hasPrefix("///") {
            // Doc exists but may be misplaced (between @available and public func)
            // Find the doc block
            var docEnd = checkIdx
            var docStart = checkIdx
            while docStart > 0, result[docStart - 1].trimmingCharacters(in: .whitespaces).hasPrefix("///") {
                docStart -= 1
            }
            // If doc is below some @attributes, move it above them
            let attrStart = insertPosition(in: result, before: docStart)
            if attrStart < docStart {
                let docBlock = Array(result[docStart...docEnd])
                result.removeSubrange(docStart...docEnd)
                let shift = docBlock.count
                let newInsert = attrStart
                for (j, docLine) in docBlock.enumerated() {
                    result.insert(docLine, at: newInsert + j)
                }
                // Net change is 0 — no offset adjustment
            }
            fixed += 1
            continue
        }

        // Look for a preceding // comment to convert
        if let (start, end) = precedingPlainComment(in: result, before: insertAt) {
            for i in start...end {
                let old = result[i]
                let new = old.replacingOccurrences(of: "^(\\s*)(//(?!//))", with: "$1///", options: .regularExpression)
                result[i] = new
            }
        } else {
            let doc = generateDoc(for: line, in: result, at: idx, indent: indent)
            result.insert(doc + "\n", at: insertAt)
            offset += 1
        }
        fixed += 1
    }

    if fixed > 0 {
        try? result.joined().write(toFile: filepath, atomically: true, encoding: .utf8)
    }
    return fixed
}

// MARK: - Main

let violations = getViolations()
print("Found missing_docs violations in \(violations.count) files")

var total = 0
for (file, lines) in violations.sorted(by: { $0.key < $1.key }) {
    let fixed = fixFile(file, violatingLines: lines)
    if fixed > 0 {
        print("  Fixed \(fixed) in \((file as NSString).lastPathComponent)")
        total += fixed
    }
}

print("\nTotal: \(total) docs added/converted")
