#!/usr/bin/env swift
// SPDX-License-Identifier: Apache-2.0
//
// Fixes `switch_case_on_newline` SwiftLint violations.
// Converts `case PATTERN: body` to multi-line form.
//
// Usage: swift docs/scripts/fix-switch-cases.swift
// Run from the repo root. Requires `mint` on PATH.

import Foundation

// MARK: - Shell helpers

func shell(_ args: [String]) -> (output: String, exitCode: Int32) {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    proc.arguments = args
    let pipe = Pipe()
    proc.standardOutput = pipe
    proc.standardError = pipe
    try? proc.run()
    proc.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return (String(data: data, encoding: .utf8) ?? "", proc.terminationStatus)
}

// MARK: - Violation parsing

struct Violation {
    let file: String
    let line: Int
}

func getViolations(rule: String) -> [String: Set<Int>] {
    let (output, _) = shell(["mint", "run", "swiftlint", "lint", "--strict"])
    var violations: [String: Set<Int>] = [:]
    for line in output.components(separatedBy: "\n") {
        guard line.contains(rule) else { continue }
        let parts = line.components(separatedBy: ":")
        guard parts.count >= 2, let lineno = Int(parts[1]) else { continue }
        let filepath = parts[0]
        violations[filepath, default: []].insert(lineno)
    }
    return violations
}

// MARK: - Case splitting

/// Splits a line like `    case PATTERN: body` into `(caseLine, bodyLine)`.
/// Returns nil if the line doesn't match the expected pattern.
func splitCaseBody(_ line: String) -> (String, String)? {
    let stripped = line.hasSuffix("\n") ? String(line.dropLast()) : line
    let trimmed = stripped.trimmingCharacters(in: .init(charactersIn: " "))
    let leading = stripped.count - stripped.drop(while: { $0 == " " }).count
    guard trimmed.hasPrefix("case ") || trimmed == "default:" || trimmed.hasPrefix("default: ") else {
        return nil
    }

    var depth = 0
    var inString = false
    var stringChar: Character = "\""
    var i = trimmed.startIndex

    while i < trimmed.endIndex {
        let c = trimmed[i]
        if inString {
            if c == "\\" { trimmed.formIndex(after: &i); trimmed.formIndex(after: &i); continue }
            if c == stringChar { inString = false }
        } else {
            switch c {
            case "\"",
                 "'": inString = true; stringChar = c
            case "(",
                 "[": depth += 1
            case ")",
                 "]": depth -= 1
            case ":" where depth == 0:
                let afterColon = trimmed[trimmed.index(after: i)...]
                let bodyPart = afterColon.drop(while: { $0 == " " })
                guard !bodyPart.isEmpty, !bodyPart.hasPrefix("//") else { return nil }
                let indent = String(repeating: " ", count: leading)
                let casePart = indent + String(trimmed[..<trimmed.index(after: i)])
                let bodyIndent = indent + "    "
                return (casePart, bodyIndent + String(bodyPart))
            default: break
            }
        }
        trimmed.formIndex(after: &i)
    }
    return nil
}

// MARK: - File processing

func fixFile(_ filepath: String, violatingLines: Set<Int>) -> Int {
    guard let content = try? String(contentsOfFile: filepath, encoding: .utf8) else { return 0 }
    var lines = content.components(separatedBy: "\n").map { $0 + "\n" }
    // Last element is "" after splitting on trailing newline
    if lines.last == "\n", content.hasSuffix("\n") {
        lines.removeLast()
    }

    var result = lines
    var offset = 0
    var fixed = 0

    for origLine in violatingLines.sorted() {
        let idx = origLine - 1 + offset
        guard idx < result.count else { continue }
        let line = result[idx]
        guard let (casePart, bodyPart) = splitCaseBody(line) else { continue }
        result[idx..<(idx + 1)] = [casePart + "\n", bodyPart + "\n"]
        offset += 1
        fixed += 1
    }

    if fixed > 0 {
        let newContent = result.joined()
        try? newContent.write(toFile: filepath, atomically: true, encoding: .utf8)
    }
    return fixed
}

// MARK: - Main

let violations = getViolations(rule: "switch_case_on_newline")
print("Found switch_case_on_newline violations in \(violations.count) files")

var total = 0
for (file, lines) in violations.sorted(by: { $0.key < $1.key }) {
    let fixed = fixFile(file, violatingLines: lines)
    if fixed > 0 {
        print("  Fixed \(fixed) in \((file as NSString).lastPathComponent)")
        total += fixed
    }
}

print("\nTotal fixed: \(total)")
