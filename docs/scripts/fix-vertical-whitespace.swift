#!/usr/bin/env swift
// SPDX-License-Identifier: Apache-2.0
//
// Fixes `vertical_whitespace_between_cases` SwiftLint violations.
// Inserts a blank line before each case that is missing one.
//
// Usage: swift docs/scripts/fix-vertical-whitespace.swift
// Run from the repo root. Requires `mint` on PATH.

import Foundation

func shell(_ args: [String]) -> String {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    proc.arguments = args
    let pipe = Pipe()
    proc.standardOutput = pipe
    proc.standardError = pipe
    try? proc.run()
    proc.waitUntilExit()
    return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
}

func getViolations(rule: String) -> [String: Set<Int>] {
    let output = shell(["mint", "run", "swiftlint", "lint", "--strict"])
    var violations: [String: Set<Int>] = [:]
    for line in output.components(separatedBy: "\n") {
        guard line.contains(rule) else { continue }
        let parts = line.components(separatedBy: ":")
        guard parts.count >= 2, let lineno = Int(parts[1]) else { continue }
        violations[parts[0], default: []].insert(lineno)
    }
    return violations
}

func fixFile(_ filepath: String, violatingLines: Set<Int>) -> Int {
    guard let content = try? String(contentsOfFile: filepath, encoding: .utf8) else { return 0 }
    var lines = content.components(separatedBy: "\n").map { $0 + "\n" }
    if lines.last == "\n" && content.hasSuffix("\n") { lines.removeLast() }

    var result = lines
    var offset = 0

    for origLine in violatingLines.sorted() {
        let idx = origLine - 1 + offset
        guard idx < result.count else { continue }
        result.insert("\n", at: idx)
        offset += 1
    }

    if offset > 0 {
        try? result.joined().write(toFile: filepath, atomically: true, encoding: .utf8)
    }
    return offset
}

let violations = getViolations(rule: "vertical_whitespace_between_cases")
print("Found violations in \(violations.count) files")

var total = 0
for (file, lines) in violations.sorted(by: { $0.key < $1.key }) {
    let fixed = fixFile(file, violatingLines: lines)
    if fixed > 0 {
        print("  Fixed \(fixed) in \((file as NSString).lastPathComponent)")
        total += fixed
    }
}
print("\nTotal blank lines inserted: \(total)")
