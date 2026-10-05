#!/usr/bin/env swift
// SPDX-License-Identifier: Apache-2.0
//
// Dev-time documentation audit: type-checks every ```swift fenced block found in README.md,
// `Sources/**/*.docc/**/*.md` and `docs/claude-skills/**/*.md` against the built package.
//
// Run from the package root, after `swift build`:
//
//     swift Scripts/CheckDocSnippets.swift [output.md] [--only FILE] [--verbose] [--dump PATH]   # default: docs/audit/snippets.md
//
// Nothing is added to the package: blocks are written to a scratch directory under $TMPDIR and checked
// with `swiftc -typecheck` against `.build/debug/Modules` (plus the FPMacrosPlugin executable).
//
// Convention: every block fenced ```swift must compile when the blocks of one file are concatenated top to bottom.
// Illustrative fragments use the fence ```swift-sketch and are skipped (and counted).
//
// Top-level declaration chunks (type/func/extension/import/...) are hoisted to file scope, so a name can be declared
// only once per file; statement chunks run in order inside one `async throws` function, each block in its own `do`
// scope. `#sourceLocation` maps compiler errors back to the doc.

import Foundation

// MARK: - Model

struct Block {
    let file: String
    let line: Int // line of the first content line (1-based)
    let lines: [String]
    var skipReason: String?
}

let fm = FileManager.default
let root = fm.currentDirectoryPath
let args = Array(CommandLine.arguments.dropFirst())
// `--only README.md` limits the run to one file; `--verbose` prints every compiler error of the cumulative pass.
let only = args.firstIndex(of: "--only").flatMap { args.indices.contains($0 + 1) ? args[$0 + 1] : nil }
let verbose = args.contains("--verbose")
// `--dump PATH` writes the concatenated source of the (last) cumulative check, for debugging.
let dumpPath = args.firstIndex(of: "--dump").flatMap { args.indices.contains($0 + 1) ? args[$0 + 1] : nil }
let outPath = args.first(where: { !$0.hasPrefix("--") && $0 != only && $0 != dumpPath }) ?? "docs/audit/snippets.md"

// MARK: - Discovery

func markdownFiles() -> [String] {
    var result = ["README.md"]
    for base in ["Sources", "docs/claude-skills"] {
        guard let e = fm.enumerator(atPath: base) else { continue }
        for case let p as String in e where p.hasSuffix(".md") {
            if base == "Sources", !p.contains(".docc/") { continue }
            result.append("\(base)/\(p)")
        }
    }
    return result.sorted().filter { only == nil || $0 == only }
}

func extractBlocks(file: String) -> [Block] {
    guard let text = try? String(contentsOfFile: file, encoding: .utf8) else { return [] }
    let all = text.components(separatedBy: "\n")
    var blocks: [Block] = []
    var i = 0
    while i < all.count {
        let trimmed = all[i].trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("```swift") {
            let tag = String(trimmed.dropFirst(3))
            var body: [String] = []
            var j = i + 1
            while j < all.count, !all[j].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                body.append(all[j])
                j += 1
            }
            // Strip the fence indentation, if any.
            let indent = all[i].prefix(while: { $0 == " " }).count
            body = body.map { l in
                l.prefix(indent).allSatisfy { $0 == " " } ? String(l.dropFirst(indent)) : l
            }
            var block = Block(file: file, line: i + 2, lines: body, skipReason: nil)
            if tag != "swift" { block.skipReason = tag == "swift-sketch" ? "sketch" : "fence tagged `\(tag)`" }
            blocks.append(block)
            i = j + 1
        } else {
            i += 1
        }
    }
    return blocks
}

// MARK: - Wrapping

let declKeywords = [
    "import", "struct", "enum", "class", "actor", "protocol", "extension", "func", "typealias", "infix", "prefix",
    "postfix", "precedencegroup", "public", "internal", "private", "fileprivate", "final", "indirect", "@", "#if",
    "#endif", "#else", "#elseif", "nonisolated", "open", "macro", "associatedtype"
]

func isDeclStart(_ line: String) -> Bool {
    declKeywords.contains { kw in
        guard line.hasPrefix(kw) else { return false }
        if kw == "@" { return true }
        guard let next = line.dropFirst(kw.count).first else { return true }
        return !(next.isLetter || next.isNumber || next == "_")
    }
}

struct Chunk {
    let line: Int
    let lines: [String]
    let isDecl: Bool
}

/// Splits a block into column-0 chunks (tracking bracket depth so bodies stay with their header).
func chunks(of block: Block) -> [Chunk] {
    var result: [Chunk] = []
    var current: [String] = []
    var currentLine = block.line
    var depth = 0
    func flush() {
        defer { current = [] }
        guard !current.allSatisfy({ $0.trimmingCharacters(in: .whitespaces).isEmpty }) else { return }
        let first = current.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty && !$0.hasPrefix("//") }) ?? ""
        result.append(Chunk(line: currentLine, lines: current, isDecl: isDeclStart(first)))
    }
    let continuers = ["}", ")", "]", ".", "|>", ">>>", "<", ">", "//", "#else", "#endif", "#elseif"]
    for (offset, raw) in block.lines.enumerated() {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        let startsNew = depth <= 0 && !raw.hasPrefix(" ") && !raw.hasPrefix("\t") && !trimmed.isEmpty
            && !continuers.contains(where: { trimmed.hasPrefix($0) })
        // A lone attribute line (`@Lenses`) belongs to the declaration on the next line.
        let lastTrimmed = current.last(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?
            .trimmingCharacters(in: .whitespaces) ?? ""
        let pendingAttribute = depth <= 0
            && lastTrimmed.range(of: #"^(@[A-Za-z_][A-Za-z0-9_.<>, ]*(\(.*\))?\s*)+$"#, options: .regularExpression) != nil
        if startsNew, !current.isEmpty, !pendingAttribute { flush() }
        if current.isEmpty { currentLine = block.line + offset }
        current.append(raw)
        // Crude depth tracking, ignoring line comments and string literals.
        var inString = false
        var prev: Character = " "
        for c in raw {
            if !inString, c == "/", prev == "/" { break }
            if c == "\"", prev != "\\" { inString.toggle() }
            if !inString {
                if "{([".contains(c) { depth += 1 }
                if "})]".contains(c) { depth -= 1 }
            }
            prev = c
        }
        if depth < 0 { depth = 0 }
    }
    flush()
    return result
}

let preamble = """
import Foundation
import FP
import FPMacros
#if canImport(Combine)
import Combine
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

"""

func render(_ blocks: [Block]) -> String {
    var top = ""
    var body = ""
    for block in blocks {
        var scoped = ""
        for chunk in chunks(of: block) {
            let text = "#sourceLocation(file: \"\(block.file)\", line: \(chunk.line))\n"
                + chunk.lines.joined(separator: "\n") + "\n#sourceLocation()\n"
            if chunk.isDecl { top += text } else { scoped += text }
        }
        if !scoped.isEmpty { body += "do {\n" + scoped + "}\n" }
    }
    return preamble + "\n" + top + "\nfunc _docSnippets() async throws {\n" + body + "}\n"
}

// MARK: - Compiler

let sdk: String = {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    p.arguments = ["--show-sdk-path"]
    let pipe = Pipe()
    p.standardOutput = pipe
    try? p.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
}()

func swiftc(_ source: String, name: String, parseOnly: Bool, scratch: String) -> [String] {
    let path = "\(scratch)/\(name).swift"
    try? source.write(toFile: path, atomically: true, encoding: .utf8)
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    var args = ["swiftc", parseOnly ? "-parse" : "-typecheck", "-swift-version", "6", "-D", "DEBUG"]
    if !sdk.isEmpty { args += ["-sdk", sdk] }
    args += [
        "-I", "\(root)/.build/debug/Modules", "-I", "\(root)/.build/debug",
        "-load-plugin-executable", "\(root)/.build/debug/FPMacrosPlugin-tool#FPMacrosPlugin", path
    ]
    p.arguments = args
    let pipe = Pipe()
    p.standardError = pipe
    p.standardOutput = pipe
    do { try p.run() } catch { return ["\(path):0:0: error: could not launch swiftc: \(error)"] }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return String(decoding: data, as: UTF8.self).components(separatedBy: "\n").filter { $0.contains(": error: ") }
}

/// `file:line:col: error: message` -> (file, line, message)
func parseError(_ s: String) -> (String, Int, String)? {
    guard let r = s.range(of: ": error: ") else { return nil }
    let parts = s[..<r.lowerBound].split(separator: ":", omittingEmptySubsequences: false)
    guard parts.count >= 3, let line = Int(parts[parts.count - 2]) else { return nil }
    return (parts[0 ..< parts.count - 2].joined(separator: ":"), line, String(s[r.upperBound...]))
}

// MARK: - Main

let scratch = NSTemporaryDirectory() + "docsnippets-\(getpid())"
try? fm.createDirectory(atPath: scratch, withIntermediateDirectories: true)

guard fm.fileExists(atPath: ".build/debug/Modules/FP.swiftmodule") else {
    FileHandle.standardError.write(Data("Run `swift build` first (needs .build/debug/Modules).\n".utf8))
    exit(1)
}

var perFile: [(String, [Block])] = []
for f in markdownFiles() {
    let b = extractBlocks(file: f)
    if !b.isEmpty { perFile.append((f, b)) }
}

let flat: [Block] = perFile.flatMap { $0.1 }

// Syntax errors are found per block (so one broken block cannot hide the rest), then every other non-skipped block of a
// file is type-checked together, in order.
final class Results: @unchecked Sendable { // every access goes through `lock`
    let lock = NSLock()
    var failures: [String: [(line: Int, message: String)]] = [:]
}

let results = Results()

func record(_ file: String, _ line: Int, _ message: String) {
    results.lock.lock()
    results.failures[file, default: []].append((line, message))
    results.lock.unlock()
}

var syntaxBroken = Set<String>() // "file:line"
let runnable = flat.filter { $0.skipReason == nil }
DispatchQueue.concurrentPerform(iterations: runnable.count) { idx in
    let block = runnable[idx]
    let errs = swiftc(render([block]), name: "syn\(idx)", parseOnly: true, scratch: scratch)
    if let e = errs.compactMap(parseError).first(where: { $0.0 == block.file }) {
        record(block.file, block.line, "\(e.1): \(e.2)")
        results.lock.lock()
        syntaxBroken.insert("\(block.file):\(block.line)")
        results.lock.unlock()
    }
}

DispatchQueue.concurrentPerform(iterations: perFile.count) { idx in
    let (file, blocks) = perFile[idx]
    results.lock.lock()
    let broken = syntaxBroken
    results.lock.unlock()
    let ok = blocks.filter { $0.skipReason == nil && !broken.contains("\($0.file):\($0.line)") }
    guard !ok.isEmpty else { return }
    let source = render(ok)
    if let dumpPath { try? source.write(toFile: dumpPath, atomically: true, encoding: .utf8) }
    let errs = swiftc(source, name: "cum\(idx)", parseOnly: false, scratch: scratch)
    var seen = Set<Int>()
    if verbose { errs.forEach { print($0) } }
    for e in errs.compactMap(parseError) where e.0 == file {
        guard let start = ok.map(\.line).last(where: { $0 <= e.1 }), seen.insert(start).inserted else { continue }
        record(file, start, "\(e.1): \(e.2)")
    }
}

try? fm.removeItem(atPath: scratch)

// MARK: - Report

var out = "# Doc snippet compile check\n\n"
out += "Generated by `Scripts/CheckDocSnippets.swift` (Swift 6 mode, `swiftc -typecheck` against `.build/debug`).\n\n"
out += "Convention: a ```swift block must compile when all ```swift blocks of its file are concatenated top to bottom;\n"
out += "```swift-sketch blocks are illustrative and skipped.\n\n"
var totalBlocks = 0
var totalFailing = 0
var totalSketch = 0
var rows: [(String, Int, Int, Int)] = []
var detail = ""
for (file, blocks) in perFile {
    let sketches = blocks.filter { $0.skipReason != nil }.count
    let fails = (results.failures[file] ?? []).sorted { $0.line < $1.line }
    totalBlocks += blocks.count - sketches
    totalFailing += fails.count
    totalSketch += sketches
    rows.append((file, blocks.count - sketches, fails.count, sketches))
    guard !fails.isEmpty else { continue }
    detail += "## \(file)\n\n| Block line | First error (doc line: message) |\n|---|---|\n"
    for f in fails {
        detail += "| \(f.line) | `\(f.message.replacingOccurrences(of: "|", with: "\\|"))` |\n"
    }
    detail += "\n"
}

out += "## Totals\n\n- Files with Swift blocks: \(perFile.count)\n- Checked blocks: \(totalBlocks)\n- Failing: \(totalFailing)\n"
out += "- Sketch (skipped): \(totalSketch)\n"
out += "\n## Per file\n\n| File | Checked | Failing | Sketch |\n|---|---|---|---|\n"
for r in rows.sorted(by: { $0.2 > $1.2 }) {
    out += "| \(r.0) | \(r.1) | \(r.2) | \(r.3) |\n"
}

out += "\n# Failures\n\n" + detail
try? out.write(toFile: outPath, atomically: true, encoding: .utf8)
print("checked=\(totalBlocks) failing=\(totalFailing) sketch=\(totalSketch) -> \(outPath)")
for r in rows where r.0 == "README.md" {
    print("README.md: checked=\(r.1) failing=\(r.2) sketch=\(r.3)")
}
