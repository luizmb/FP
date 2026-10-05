#!/usr/bin/env swift
// SPDX-License-Identifier: Apache-2.0
//
// Dev-time documentation audit: type-checks every ```swift fenced block found in README.md,
// `Sources/**/*.docc/**/*.md` and `docs/claude-skills/**/*.md` against the built package.
//
// Run from the package root, after `swift build`:
//
//     swift Scripts/CheckDocSnippets.swift [output.md]      # default: docs/audit/snippets.md
//
// Nothing is added to the package: blocks are written to a scratch directory under $TMPDIR and checked
// with `swiftc -typecheck` against `.build/debug/Modules` (plus the FPMacrosPlugin executable).
//
// Two passes per block:
//   isolated   the block alone (syntax errors are detected here)
//   cumulative every non-skipped block of the same file, in order, in one scope (this is how the articles read)
// Top-level declaration chunks (type/func/extension/import/...) are hoisted to file scope; statement chunks are
// placed, in order, inside one `async throws` function. `#sourceLocation` maps compiler errors back to the doc.
//
// A block is skipped when its fence is tagged `swift-pseudo` / `swift-skip`, or when its first line is a
// `// pseudo` comment.

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
let outPath = CommandLine.arguments.dropFirst().first ?? "docs/audit/snippets.md"

// MARK: - Discovery

func markdownFiles() -> [String] {
    var result = ["README.md"]
    for base in ["Sources", "docs/claude-skills"] {
        guard let e = fm.enumerator(atPath: base) else { continue }
        for case let p as String in e where p.hasSuffix(".md") {
            if base == "Sources" && !p.contains(".docc/") { continue }
            result.append("\(base)/\(p)")
        }
    }
    return result.sorted()
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
            if tag != "swift" {
                block.skipReason = "fence tagged `\(tag)`"
            } else if body.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?
                .trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("// pseudo") == true {
                block.skipReason = "leading `// pseudo` comment"
            }
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
        let pendingAttribute = lastTrimmed.hasPrefix("@") && !lastTrimmed.contains(" ") && depth <= 0
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
        for chunk in chunks(of: block) {
            let text = "#sourceLocation(file: \"\(block.file)\", line: \(chunk.line))\n"
                + chunk.lines.joined(separator: "\n") + "\n#sourceLocation()\n"
            if chunk.isDecl { top += text } else { body += text }
        }
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
    var args = ["swiftc", parseOnly ? "-parse" : "-typecheck", "-swift-version", "6"]
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

// MARK: - Cause guesses

let librarySource: String = {
    guard let e = fm.enumerator(atPath: "Sources") else { return "" }
    var all = ""
    for case let p as String in e where p.hasSuffix(".swift") {
        all += (try? String(contentsOfFile: "Sources/\(p)", encoding: .utf8)) ?? ""
        all += "\n"
    }
    return all
}()

func libraryDeclares(_ name: String) -> Bool {
    guard let re = try? NSRegularExpression(
        pattern: "(func|struct|enum|class|actor|protocol|typealias|case|var|let|macro|init)\\s+`?\(NSRegularExpression.escapedPattern(for: name))\\b"
    ) else { return false }
    return re.firstMatch(in: librarySource, range: NSRange(librarySource.startIndex..., in: librarySource)) != nil
}

func quotedName(_ m: String) -> String? {
    guard let a = m.firstIndex(of: "'"), let b = m[m.index(after: a)...].firstIndex(of: "'") else { return nil }
    return String(m[m.index(after: a) ..< b])
}

/// Returns (text, isLikelyRealOutdatedAPI). `message` is "docLine: compiler message".
func guess(_ full: String, block: Block) -> (String, Bool) {
    let m = full.drop(while: { $0.isNumber }).dropFirst(2).description
    let text = block.lines.joined(separator: "\n")
    if m.contains("invalid redeclaration") || m.contains("already declared") || m.contains("ambiguous for type lookup") {
        return ("harness: name redeclared across blocks of one file", false)
    }
    if m.hasPrefix("cannot find '") || m.hasPrefix("cannot find type '") {
        if let n = quotedName(m) {
            if libraryDeclares(n) {
                return ("`\(n)` exists in Sources but is not in scope here (missing qualifier/import, or signature moved)", true)
            }
            return ("`\(n)` not declared in Sources: user-defined in prose (missing context) or removed/renamed API", false)
        }
        return ("missing context", false)
    }
    if m.contains("unary operator cannot be separated") || m.contains("expected declaration") && text.contains("...") {
        return ("harness: `{ ... }` elision / ellipsis in snippet", false)
    }
    if text.contains("{ ... }") || text.contains("/* ... */") { return ("harness: `...` elision in snippet", false) }
    if m.contains("non-Sendable function value") {
        return ("Swift 6 mode: closure/function not @Sendable; doc style or real (library is Sendable-first)", true)
    }
    if m.contains("property wrappers are not yet supported in top-level code") {
        return ("harness: property wrapper in statement scope", false)
    }
    if m.contains("adjacent operators are in unordered precedence groups") {
        return ("operator precedence mismatch (possibly outdated operator choice; check manually)", true)
    }
    if m.contains("has no member") { return ("renamed/removed member (likely outdated API)", true) }
    if m.contains("extra argument") || m.contains("missing argument") || m.contains("incorrect argument label") ||
        m.contains("cannot convert value of type") || m.contains("generic parameter") ||
        m.contains("is not a member type") || m.contains("requires that") || m.contains("cannot call value") ||
        m.contains("does not conform") {
        return ("signature/type mismatch (possibly outdated API, or missing context types; check manually)", true)
    }
    if m.contains("expected") || m.contains("consecutive") || m.contains("unexpected") || m.contains("cannot parse") {
        return ("syntax error: pseudo-code, ellipsis or fragment", false)
    }
    if m.contains("no such module") { return ("harness: module unavailable", false) }
    if m.contains("expressions are not allowed") { return ("harness: top-level statement placement", false) }
    return ("unclassified (inspect manually)", false)
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

struct Key: Hashable {
    let file: String
    let line: Int
}

final class Results: @unchecked Sendable { // every access goes through `lock`
    let lock = NSLock()
    var syntax: [Key: String] = [:]
    var isolated: [Key: String] = [:]
    var cumulative: [Key: String] = [:]
}
let results = Results()

// Pass 1: isolated, in parallel.
let runnable = flat.filter { $0.skipReason == nil }
DispatchQueue.concurrentPerform(iterations: runnable.count) { idx in
    let block = runnable[idx]
    let src = render([block])
    let key = Key(file: block.file, line: block.line)
    let syn = swiftc(src, name: "iso\(idx)p", parseOnly: true, scratch: scratch)
    if let e = syn.compactMap(parseError).first(where: { $0.0 == block.file }) {
        results.lock.lock()
        results.syntax[key] = "\(e.1): \(e.2)"
        results.isolated[key] = "\(e.1): \(e.2)"
        results.lock.unlock()
        return
    }
    let errs = swiftc(src, name: "iso\(idx)", parseOnly: false, scratch: scratch)
    if let e = errs.compactMap(parseError).first(where: { $0.0 == block.file }) {
        results.lock.lock()
        results.isolated[key] = "\(e.1): \(e.2)"
        results.lock.unlock()
    }
}

// Pass 2: cumulative per file (syntax-broken blocks excluded so they cannot hide other errors).
DispatchQueue.concurrentPerform(iterations: perFile.count) { idx in
    let (file, blocks) = perFile[idx]
    results.lock.lock()
    let syntaxKeys = Set(results.syntax.keys)
    results.lock.unlock()
    let ok = blocks.filter { $0.skipReason == nil && !syntaxKeys.contains(Key(file: file, line: $0.line)) }
    guard !ok.isEmpty else { return }
    let errs = swiftc(render(ok), name: "cum\(idx)", parseOnly: false, scratch: scratch)
    let starts = ok.map(\.line)
    results.lock.lock()
    for e in errs.compactMap(parseError) where e.0 == file {
        guard let start = starts.last(where: { $0 <= e.1 }) else { continue }
        let k = Key(file: file, line: start)
        if results.cumulative[k] == nil { results.cumulative[k] = "\(e.1): \(e.2)" }
    }
    results.lock.unlock()
}
try? fm.removeItem(atPath: scratch)

// MARK: - Report

var out = "# Doc snippet compile check\n\n"
out += "Generated by `Scripts/CheckDocSnippets.swift` (Swift 6 mode, `swiftc -typecheck` against `.build/debug`).\n\n"
out += "A block is **failing** if it has a syntax error in isolation, or a compiler error when all non-skipped blocks of\n"
out += "its file are type-checked in order in one scope (cumulative). The `iso` column says whether it also fails alone.\n"
out += "Causes are heuristic guesses from the first error message; `API?` = likely real outdated API, otherwise a harness\n"
out += "limitation or missing context (verify before fixing).\n\n"

var totalBlocks = 0
var totalFailing = 0
var totalSkipped = 0
var totalRealAPI = 0
var skipReasons: [String: Int] = [:]
var rows: [(String, Int, Int, Int)] = []
var detail = ""
for (file, blocks) in perFile {
    var failing: [(Block, String, Bool, Bool)] = [] // block, message, alsoFailsIsolated, syntax
    var skipped = 0
    for b in blocks {
        if let r = b.skipReason {
            skipped += 1
            skipReasons[r, default: 0] += 1
            continue
        }
        let k = Key(file: file, line: b.line)
        if let s = results.syntax[k] {
            failing.append((b, s, true, true))
        } else if let c = results.cumulative[k] {
            failing.append((b, c, results.isolated[k] != nil, false))
        }
    }
    totalBlocks += blocks.count
    totalFailing += failing.count
    totalSkipped += skipped
    rows.append((file, blocks.count, failing.count, skipped))
    guard !failing.isEmpty else { continue }
    detail += "## \(file)\n\n| Block line | iso | First error (doc line: message) | Likely cause |\n|---|---|---|---|\n"
    for (b, msg, iso, _) in failing {
        let (cause, real) = guess(msg, block: b)
        if real { totalRealAPI += 1 }
        let clean = msg.replacingOccurrences(of: "|", with: "\\|")
        detail += "| \(b.line) | \(iso ? "fail" : "pass") | `\(clean)` | \(real ? "API? " : "")\(cause) |\n"
    }
    detail += "\n"
}

out += "## Totals\n\n- Files with Swift blocks: \(perFile.count)\n- Blocks: \(totalBlocks)\n- Failing: \(totalFailing)\n"
out += "- Skipped: \(totalSkipped)\n- Failing and flagged as likely real outdated API: \(totalRealAPI)\n"
for (r, n) in skipReasons.sorted(by: { $0.key < $1.key }) { out += "  - skipped (\(r)): \(n)\n" }
out += "\n## Per file\n\n| File | Blocks | Failing | Skipped |\n|---|---|---|---|\n"
for r in rows.sorted(by: { $0.2 > $1.2 }) { out += "| \(r.0) | \(r.1) | \(r.2) | \(r.3) |\n" }
out += "\n# Failures\n\n" + detail
try? out.write(toFile: outPath, atomically: true, encoding: .utf8)
print("blocks=\(totalBlocks) failing=\(totalFailing) skipped=\(totalSkipped) -> \(outPath)")
