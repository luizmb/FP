#!/usr/bin/env swift
// SPDX-License-Identifier: Apache-2.0
//
// Generates the newtype monad-transformer stacks (`ReaderTArray`, `WriterTOptional`, …).
//
// Run from the package root:
//
//     swift Scripts/GenerateTransformers.swift
//
// The output is checked in. Library consumers never run this script and it adds no build-time
// dependency. Every file under `Sources/*/Transformer/Generated/` is owned by this script: the
// directories are wiped and rewritten on each run, so never edit them by hand.
//
// Adding a stack: add one `Stack(...)` line to `inventory` below and re-run. A stack is described by
// its outer and inner `Layer`, its `Kind` (functor only, applicative-only `TransformerStack`, or
// lawful-monad `MonadT`) and, for stacks whose nested-type functions don't follow the usual names,
// a few `Override`s. See CONTRIBUTING.md ("Transformer stacks") for the full rules.

import Foundation

// MARK: - Model

/// One layer of a stack. The same layer behaves differently as the outer and as the inner layer.
enum Layer: String, CaseIterable {
    case array = "Array"
    case optional = "Optional"
    case result = "Result"
    case either = "Either"
    case nonEmpty = "NonEmpty"
    case writer = "Writer"
    case validation = "Validation"
    case reader = "Reader"
    case stateful = "Stateful"
    case publisher = "Publisher"
    case asyncStream = "AsyncStream"

    /// Name used in struct names and in the nested-type free functions (`applyReaderArray`).
    var name: String { rawValue }

    /// Lifting property on the outer type (`reader.readerT`).
    var liftName: String { name.prefix(1).lowercased() + name.dropFirst() + "T" }

    /// Context parameters this layer adds as the OUTER layer, with their declaration constraint.
    var outerParams: [Param] {
        switch self {
        case .array,
             .optional,
             .nonEmpty,
             .asyncStream: []
        case .result: [Param("E", "Error")]
        case .either: [Param("L")]
        case .writer: [Param("W", "Monoid")]
        case .validation: [Param("E", "Semigroup")]
        case .reader: [Param("Env")]
        case .stateful: [Param("S")]
        case .publisher: [Param("Failure", "Error")]
        }
    }

    /// Context parameters this layer adds as the INNER layer.
    var innerParams: [Param] {
        switch self {
        case .array,
             .optional,
             .nonEmpty,
             .asyncStream: []
        case .result,
             .publisher: [Param("E", "Error")]
        case .either: [Param("L")]
        case .writer: [Param("W", "Monoid")]
        case .validation: [Param("E", "Semigroup")]
        case .reader: [Param("Env")]
        case .stateful: [Param("S")]
        }
    }

    /// The layer's type around `inner`, using the given context parameter names.
    func type(around inner: String, _ ctx: [String], asInner: Bool) -> String {
        switch self {
        case .array: "[\(inner)]"
        case .optional: "\(inner)?"
        case .result: "Result<\(inner), \(ctx[0])>"
        case .either: "Either<\(ctx[0]), \(inner)>"
        case .nonEmpty: "NonEmpty<\(inner)>"
        case .writer: "Writer<\(ctx[0]), \(inner)>"
        case .validation: "Validation<\(ctx[0]), \(inner)>"
        case .reader: "Reader<\(ctx[0]), \(inner)>"
        case .stateful: "Stateful<\(ctx[0]), \(inner)>"
        case .publisher: asInner ? "any Publisher<\(inner), \(ctx[0])>" : "AnyPublisher<\(inner), \(ctx[0])>"
        case .asyncStream: "AsyncStream<\(inner)>"
        }
    }

    /// `pure` of the layer as the outer layer, around the inner `pure` expression.
    func outerPure(_ inner: String) -> String {
        switch self {
        case .publisher: "Just(\(inner)).setFailureType(to: Failure.self).eraseToAnyPublisher()"
        case .asyncStream: "AsyncStream.just(\(inner))"
        default: ".pure(\(inner))"
        }
    }

    /// The module that owns the layer's type.
    var isCore: Bool { [.array, .optional, .result, .publisher, .asyncStream].contains(self) }

    /// How the outer type is extended with the lifting property.
    var lift: Lift {
        switch self {
        case .array: Lift(ext: "Array", elem: "Element", ctx: [], convert: { _ in "Element.coerceArray(self)" })
        case .optional: Lift(ext: "Optional", elem: "Wrapped", ctx: [], convert: { "map(Wrapped.\($0))" })
        case .result: Lift(ext: "Result", elem: "Success", ctx: ["Failure"], convert: { "map(Success.\($0))" })
        case .either: Lift(ext: "Either", elem: "B", ctx: ["A"], convert: { "map(B.\($0))" })
        case .nonEmpty: Lift(ext: "NonEmpty", elem: "A", ctx: [], convert: { "NonEmpty(head: A.\($0)(head), tail: A.coerceArray(tail))" })
        case .writer: Lift(ext: "Writer", elem: "A", ctx: ["W"], convert: { "mapWriter(A.\($0))" })
        case .validation: Lift(ext: "Validation", elem: "A", ctx: ["E"], convert: { "map(A.\($0))" })
        case .reader: Lift(ext: "Reader", elem: "Output", ctx: ["Environment"], convert: { "mapReader(Output.\($0))" })
        case .stateful: Lift(ext: "Stateful", elem: "A", ctx: ["S"], convert: { "mapStateful(A.\($0))" })
        case .publisher: Lift(ext: "Publisher", elem: "Output", ctx: ["Failure"], convert: { "map(Output.\($0)).eraseToAnyPublisher()" })
        case .asyncStream: Lift(ext: "AsyncStream", elem: "Element", ctx: [], convert: { _ in "Element.coerceAsyncStream(self)" })
        }
    }

    /// The inner-shape protocol constraining the lifting extension, and its identity conversion.
    var shape: Shape {
        switch self {
        case .array: Shape(proto: "ArrayLike", convert: "asArray", ctx: [], value: "Element")
        case .optional: Shape(proto: "OptionalLike", convert: "asOptional", ctx: [], value: "Wrapped")
        case .result: Shape(proto: "ResultLike", convert: "asResult", ctx: ["Failure"], value: "Success")
        case .either: Shape(proto: "EitherLike", convert: "asEither", ctx: ["Left"], value: "Right")
        case .nonEmpty: Shape(proto: "NonEmptyLike", convert: "asNonEmpty", ctx: [], value: "Element")
        case .writer: Shape(proto: "WriterLike", convert: "asWriter", ctx: ["Log"], value: "Value")
        case .validation: Shape(proto: "ValidationLike", convert: "asValidation", ctx: ["Errors"], value: "Value")
        case .reader: Shape(proto: "ReaderLike", convert: "asReader", ctx: ["Environment"], value: "Output")
        case .stateful: Shape(proto: "StatefulLike", convert: "asStateful", ctx: ["State"], value: "Value")
        case .asyncStream: Shape(proto: "AsyncStreamLike", convert: "asAsyncStream", ctx: [], value: "Element")
        // `any Publisher<A, E>` is an existential, which can't conform to a protocol: lift any concrete
        // publisher instead (implicitly erased to the existential).
        case .publisher: Shape(proto: "Publisher", convert: "", ctx: ["Failure"], value: "Output")
        }
    }
}

struct Param {
    let name: String
    let constraint: String?

    init(_ name: String, _ constraint: String? = nil) {
        self.name = name
        self.constraint = constraint
    }

    /// `Error`, `Monoid` and `Semigroup` all refine `Sendable`.
    var impliesSendable: Bool { constraint != nil }

    var declaration: String { constraint.map { "\(name): \($0)" } ?? name }

    var sendableDeclaration: String { "\(name): \(constraint ?? "Sendable")" }
}

struct Lift {
    let ext: String
    let elem: String
    let ctx: [String]
    let convert: (String) -> String
}

struct Shape {
    let proto: String
    let convert: String
    let ctx: [String]
    let value: String
}

enum Kind {
    /// Functor surface only.
    case functor
    /// Functor + applicative, no lawful monad: `TransformerStack`.
    case applicative
    /// Functor + applicative + monad: `MonadT`.
    case monad
}

/// Deviations from the default delegation to the nested-type functions.
enum Override {
    /// The stack has no `apply…` free function: derive `apply` from its `liftA2`.
    case applyViaLiftA2
    /// The stack's bind is the free function `flatMapT<Outer><Inner>(_:_:)` instead of a `flatMapT` method.
    case freeFlatMap
    /// Custom body for `map` (the nested `mapT` is not closed over the stack, e.g. `AsyncMapSequence`).
    case map(String)
    /// Custom body for `liftA2`'s returned closure (`lhs`, `rhs`, `fn` in scope); also derives `seqRight` / `seqLeft` from it.
    case liftA2(String)
    /// Custom body for `flatMap` (`fn` in scope).
    case flatMap(String)
    /// Custom body for `pure` (`value` in scope).
    case pure(String)
}

struct Stack {
    let outer: Layer
    let inner: Layer
    let kind: Kind
    let overrides: [Override]

    init(_ outer: Layer, _ inner: Layer, _ kind: Kind, _ overrides: [Override] = []) {
        self.outer = outer
        self.inner = inner
        self.kind = kind
        self.overrides = overrides
    }

    var name: String { "\(outer.name)T\(inner.name)" }
    var infix: String { "\(outer.name)\(inner.name)" }
    var isCore: Bool { outer.isCore && inner.isCore }
    var module: String { isCore ? "CoreFP" : "DataStructure" }
    var operatorModule: String { isCore ? "CoreFPOperators" : "DataStructureOperators" }
    var usesCombine: Bool { outer == .publisher || inner == .publisher }

    /// Inner context parameters, renamed when they collide with an outer one.
    var innerParams: [Param] {
        let outerNames = Set(outer.outerParams.map(\.name))
        return inner.innerParams.map { param in
            guard outerNames.contains(param.name) else { return param }
            let renamed = ["E": "Err", "Env": "InnerEnv"][param.name] ?? "Inner\(param.name)"
            return Param(renamed, param.constraint)
        }
    }

    /// `NonEmpty<X>` requires `X: Sendable`, so a NonEmpty outer forces Sendable on everything inside.
    var params: [Param] {
        let value = Param("A", inner == .nonEmpty || outer == .nonEmpty ? "Sendable" : nil)
        let inside = innerParams.map { param in
            outer == .nonEmpty && !param.impliesSendable ? Param(param.name, "Sendable") : param
        }
        return outer.outerParams + inside + [value]
    }

    var contextNames: [String] { params.dropLast().map(\.name) }

    func innerType(_ value: String, _ ctx: [String]) -> String {
        inner.type(around: value, Array(ctx.suffix(innerParams.count)), asInner: true)
    }

    func outerType(_ value: String, _ ctx: [String]) -> String {
        outer.type(around: innerType(value, ctx), Array(ctx.prefix(outer.outerParams.count)), asInner: false)
    }

    /// `O` for the given value type and context names.
    func oType(_ value: String = "A", ctx: [String]? = nil) -> String { outerType(value, ctx ?? contextNames) }

    /// `I` for the given value type.
    func iType(_ value: String = "A") -> String { innerType(value, contextNames) }

    /// The struct type applied to the given value type, e.g. `ReaderTArray<Env, B>`.
    func applied(_ value: String) -> String { "\(name)<\((contextNames + [value]).joined(separator: ", "))>" }

    /// Haskell escape-hatch name. Rule (in order):
    /// 1. by the OUTER layer for Reader / Stateful / streams: `mapReaderT`, `mapStateT`, `mapPublisherT`, `mapAsyncStreamT`;
    /// 2. by the INNER layer for Optional / Either / Result / Writer: `mapMaybeT`, `mapExceptT`, `mapWriterT`;
    /// 3. otherwise (a Compose-like stack) by the OUTER layer: `mapArrayT`, `mapOptionalT`, `mapEitherT`, ….
    var escapeHatch: String {
        switch outer {
        case .reader: return "mapReaderT"
        case .stateful: return "mapStateT"
        case .publisher: return "mapPublisherT"
        case .asyncStream: return "mapAsyncStreamT"
        default: break
        }
        switch inner {
        case .optional: return "mapMaybeT"
        case .either,
             .result: return "mapExceptT"
        case .writer: return "mapWriterT"
        default: return "map\(outer.name)T"
        }
    }

    var availability: String? {
        if inner == .publisher { return "@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)" }
        if usesCombine || outer == .asyncStream || inner == .asyncStream {
            return "@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)"
        }
        return nil
    }

    enum SendableMode { case always, conditional, never }

    var sendableMode: SendableMode {
        if outer == .publisher { return .never }
        if outer == .reader || outer == .stateful { return .always }
        if inner == .publisher { return .never }
        return params.allSatisfy(\.impliesSendable) ? .always : .conditional
    }

    /// The where-clause shared by every algebraic member: all parameters Sendable.
    var memberWhere: String {
        let missing = params.filter { !$0.impliesSendable }.map { "\($0.name): Sendable" }
        return missing.isEmpty ? "" : " where \(missing.joined(separator: ", "))"
    }

    var layersDoc: String { "outer `\(outer.name)`, inner `\(inner.name)`" }

    var customMap: String? { overrides.lazy.compactMap { if case let .map(body) = $0 { body } else { nil } }.first }
    var customLiftA2: String? { overrides.lazy.compactMap { if case let .liftA2(body) = $0 { body } else { nil } }.first }
    var customFlatMap: String? { overrides.lazy.compactMap { if case let .flatMap(body) = $0 { body } else { nil } }.first }
    var customPure: String? { overrides.lazy.compactMap { if case let .pure(body) = $0 { body } else { nil } }.first }
    var applyViaLiftA2: Bool { overrides.contains { if case .applyViaLiftA2 = $0 { true } else { false } } }
    var freeFlatMap: Bool { overrides.contains { if case .freeFlatMap = $0 { true } else { false } } }
}

// MARK: - Inventory

/// Every transformer stack of the library. Struct name = `<Outer>T<Inner>`.
let inventory: [Stack] = [
    // CoreFP
    Stack(.array, .optional, .monad),
    Stack(.array, .result, .monad),
    Stack(.publisher, .array, .applicative, [.applyViaLiftA2]),
    Stack(.publisher, .optional, .monad, [.freeFlatMap]),
    Stack(.publisher, .result, .monad, [.freeFlatMap]),
    Stack(.asyncStream, .array, .applicative, [.applyViaLiftA2]),
    Stack(.asyncStream, .optional, .monad, [.freeFlatMap]),
    Stack(.asyncStream, .result, .monad, [.freeFlatMap]),
    Stack(.optional, .array, .monad),
    Stack(.optional, .result, .monad),
    // DataStructure — Either
    Stack(.array, .either, .monad),
    Stack(.asyncStream, .either, .monad, [.freeFlatMap]),
    Stack(.either, .array, .applicative),
    Stack(.either, .nonEmpty, .applicative),
    Stack(.either, .optional, .monad, [.freeFlatMap]),
    Stack(.either, .result, .monad, [.freeFlatMap]),
    Stack(.either, .stateful, .applicative),
    Stack(.either, .validation, .applicative),
    Stack(.either, .writer, .monad),
    Stack(.optional, .either, .monad),
    Stack(.publisher, .either, .monad, [.freeFlatMap]),
    // DataStructure — NonEmpty
    Stack(.nonEmpty, .either, .monad),
    Stack(.nonEmpty, .optional, .monad),
    Stack(.nonEmpty, .result, .monad),
    Stack(.optional, .nonEmpty, .monad),
    // DataStructure — Reader
    Stack(.reader, .array, .monad),
    Stack(.reader, .asyncStream, .monad, [
        .applyViaLiftA2,
        // The nested `mapT` / `flatMapT` return `AsyncMapSequence` / `AsyncThrowingFlatMapSequence`,
        // which aren't closed over the stack; use the closed stream helpers (same concat semantics as
        // the existing `liftA2ReaderAsyncStream`).
        .map("rawValue.mapReader { AsyncStream<B>.mapStream($0, fn) }"),
        .flatMap("Reader { env in AsyncStream<B>.concatMap(rawValue(env)) { fn($0).rawValue(env) } }")
    ]),
    Stack(.reader, .either, .monad),
    Stack(.reader, .nonEmpty, .monad),
    Stack(.reader, .optional, .monad),
    Stack(.reader, .publisher, .monad, [
        .pure("Reader<Env, A>.pure(value).mapReader { Just($0).setFailureType(to: E.self) }")
    ]),
    Stack(.reader, .reader, .monad),
    Stack(.reader, .result, .monad),
    Stack(.reader, .stateful, .monad),
    Stack(.reader, .validation, .applicative),
    Stack(.reader, .writer, .monad),
    // DataStructure — Stateful
    Stack(.array, .stateful, .applicative),
    Stack(.asyncStream, .stateful, .functor, [
        .map("AsyncStream<Stateful<S, B>>.mapStream(rawValue) { $0.mapStateful(fn) }")
    ]),
    Stack(.optional, .stateful, .applicative),
    Stack(.publisher, .stateful, .applicative, [.applyViaLiftA2]),
    Stack(.result, .stateful, .applicative),
    Stack(.stateful, .array, .applicative),
    Stack(.stateful, .asyncStream, .applicative, [
        .applyViaLiftA2,
        // Closed over `AsyncStream` (the nested `mapT` returns `AsyncMapSequence`). The inner
        // applicative is AsyncStream's own `liftA2` (`ap`, cartesian, derived from concat bind), not zip.
        .map("rawValue.mapStateful { AsyncStream<B>.mapStream($0, fn) }"),
        // A fresh stream per run: `Stateful.pure(AsyncStream.just(value))` would share one single-pass
        // stream across every run of the state computation (empty from the second run on).
        .pure("Stateful<S, A>.pure(value).mapStateful { AsyncStream.just($0) }"),
        .liftA2("""
        Stateful { state in
            let streamA = lhs.rawValue.run(&state)
            let streamB = rhs.rawValue.run(&state)
            return AsyncStream<A>.liftA2(fn)(streamA, streamB)
        }
        """)
    ]),
    Stack(.stateful, .either, .monad),
    Stack(.stateful, .nonEmpty, .applicative),
    Stack(.stateful, .optional, .monad),
    Stack(.stateful, .publisher, .applicative, [
        // `applyStatefulPublisher` takes a non-`@Sendable` function stream; derive `apply` from `liftA2`.
        .applyViaLiftA2,
        .pure("Stateful<S, A>.pure(value).mapStateful { Just($0).setFailureType(to: E.self) }")
    ]),
    Stack(.stateful, .reader, .applicative),
    Stack(.stateful, .result, .monad),
    Stack(.stateful, .validation, .applicative),
    Stack(.stateful, .writer, .monad),
    // DataStructure — Validation
    Stack(.validation, .array, .applicative),
    Stack(.validation, .either, .applicative),
    Stack(.validation, .nonEmpty, .applicative),
    Stack(.validation, .optional, .applicative),
    Stack(.validation, .reader, .applicative),
    Stack(.validation, .result, .applicative),
    Stack(.validation, .stateful, .applicative),
    Stack(.validation, .writer, .applicative),
    // DataStructure — Writer
    Stack(.array, .writer, .monad),
    Stack(.asyncStream, .writer, .monad, [
        .map("AsyncStream<Writer<W, B>>.mapStream(rawValue) { $0.mapWriter(fn) }")
    ]),
    Stack(.optional, .writer, .monad),
    Stack(.publisher, .writer, .monad),
    Stack(.result, .writer, .monad),
    Stack(.writer, .array, .applicative),
    Stack(.writer, .asyncStream, .applicative, [
        // AsyncStream's own `liftA2` (`ap`: cartesian, derived from concat bind), logs combined.
        .applyViaLiftA2,
        .map("rawValue.mapWriter { AsyncStream<B>.mapStream($0, fn) }"),
        .liftA2("""
        Writer(
            AsyncStream<A>.liftA2(fn)(lhs.rawValue.value, rhs.rawValue.value),
            W.combine(lhs.rawValue.log, rhs.rawValue.log)
        )
        """)
    ]),
    Stack(.writer, .either, .monad),
    Stack(.writer, .nonEmpty, .applicative),
    Stack(.writer, .optional, .monad),
    Stack(.writer, .publisher, .applicative, [
        // `applyWriterPublisher` takes a non-`@Sendable` function stream; derive `apply` from `liftA2`.
        .applyViaLiftA2,
        .pure("Writer<W, A>.pure(value).mapWriter { Just($0).setFailureType(to: E.self) }")
    ]),
    Stack(.writer, .reader, .applicative),
    Stack(.writer, .result, .monad),
    Stack(.writer, .stateful, .applicative),
    Stack(.writer, .validation, .applicative)
]

// MARK: - Emission helpers

let header = """
// SPDX-License-Identifier: Apache-2.0
// Generated by Scripts/GenerateTransformers.swift; do not edit.
// Regenerate with `swift Scripts/GenerateTransformers.swift` from the package root.
"""

func indent(_ text: String, by level: Int = 1) -> String {
    let pad = String(repeating: "    ", count: level)
    return text.split(separator: "\n", omittingEmptySubsequences: false)
        .map { $0.isEmpty ? "" : pad + $0 }
        .joined(separator: "\n")
}

/// Indents every line but the first (the first sits at the interpolation point).
func indentTail(_ text: String, by level: Int) -> String {
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
    guard let first = lines.first else { return text }
    return ([String(first)] + lines.dropFirst().map { indent(String($0), by: level) }).joined(separator: "\n")
}

/// Renames whole-word identifiers (`A` → `B`, `Env` → `Env2`) in a type expression.
func rename(_ text: String, _ map: [String: String]) -> String {
    var output = ""
    var word = ""
    func flush() {
        output += map[word] ?? word
        word = ""
    }
    for char in text {
        if char.isLetter || char.isNumber || char == "_" {
            word.append(char)
        } else {
            flush()
            output.append(char)
        }
    }
    flush()
    return output
}

func availabilityPrefix(_ stack: Stack) -> String { stack.availability.map { "\($0)\n" } ?? "" }

func wrapCombine(_ stack: Stack, imports: [String], body: String) -> String {
    let importLines = imports.map { "import \($0)" }
    guard stack.usesCombine else {
        let importBlock = importLines.isEmpty ? "" : importLines.joined(separator: "\n") + "\n\n"
        return header + "\n\n" + importBlock + body + "\n"
    }
    let combineImports = (["Combine"] + imports).sorted().map { "import \($0)" }.joined(separator: "\n")
    return header + "\n\n#if canImport(Combine)\n" + indent(combineImports + "\n\n" + body) + "\n#endif\n"
}

// MARK: - Struct file

func structFile(_ stack: Stack) -> String {
    let avail = availabilityPrefix(stack)
    let name = stack.name
    let generics = stack.params.map(\.declaration).joined(separator: ", ")
    let conformance = stack.kind == .monad ? "MonadT" : "TransformerStack"
    let renames = Dictionary(uniqueKeysWithValues: stack.params.map { ($0.name, $0.name == "A" ? "B" : $0.name + "2") })
    let hatchGenerics = stack.params.map { Param(renames[$0.name] ?? $0.name, $0.constraint).declaration }
        .joined(separator: ", ")
    let hatchStruct = rename("\(name)<\(stack.params.map(\.name).joined(separator: ", "))>", renames)
    let kindDoc = switch stack.kind {
    case .monad: "A lawful monad (`MonadT`): functor, applicative and monad surface."
    case .applicative: "No lawful monad exists for this stack, so it is applicative-only (`TransformerStack`), like Haskell's `Compose`."
    case .functor: "Functor surface only."
    }

    var parts: [String] = []
    parts.append("""
    /// The `\(stack.oType())` stack (\(stack.layersDoc)) as its own type.
    ///
    /// \(kindDoc)
    /// Wrap a nested value with `init(_:)` or the `.\(stack.outer.liftName)` lifting property, and leave with `rawValue`.
    \(avail)public struct \(name)<\(generics)>: \(conformance) {
        /// The inner layer of the stack.
        public typealias I = \(stack.iType())
        /// The whole nested value.
        public typealias O = \(stack.outer.type(around: "I", Array(stack.contextNames.prefix(stack.outer.outerParams.count)), asInner: false))

        /// The wrapped nested value.
        public let rawValue: O

        /// Wraps a nested value.
        /// - Parameter rawValue: The nested value.
        public init(rawValue: O) {
            self.rawValue = rawValue
        }

        /// Wraps a nested value (unlabelled, for point-free use).
        /// - Parameter rawValue: The nested value.
        public init(_ rawValue: O) {
            self.rawValue = rawValue
        }

        /// Escape hatch: transforms the whole nested value, reaching the full API of the underlying types.
        /// `\(stack.escapeHatch) (fmap f)` covers "transform the inner value".
        /// - Parameter fn: Transformation of the nested value.
        /// - Returns: The stack over the transformed nested value.
        public func \(stack.escapeHatch)<\(hatchGenerics)>(
            _ fn: (O) -> \(hatchStruct).O
        ) -> \(hatchStruct) {
            \(hatchStruct)(fn(rawValue))
        }
    }
    """)

    switch stack.sendableMode {
    case .always:
        parts.append("\(avail)extension \(name): Sendable {}")
    case .conditional:
        let conditions = stack.params.filter { !$0.impliesSendable }.map { "\($0.name): Sendable" }.joined(separator: ", ")
        parts.append("\(avail)extension \(name): Sendable where \(conditions) {}")
    case .never:
        break
    }

    parts.append(functorExtension(stack))
    if stack.kind != .functor { parts.append(applicativeExtension(stack)) }
    if stack.kind == .monad { parts.append(monadExtension(stack)) }
    parts.append(liftExtension(stack))

    let imports = stack.isCore ? [] : ["CoreFP"]
    return wrapCombine(stack, imports: imports, body: parts.joined(separator: "\n\n"))
}

func functorExtension(_ stack: Stack) -> String {
    let self_ = stack.applied("A")
    let target = stack.applied("B")
    let mapBody = stack.customMap ?? "rawValue.mapT(fn)"
    return """
    // MARK: - Functor

    \(availabilityPrefix(stack))public extension \(stack.name)\(stack.memberWhere) {
        /// Maps the value inside both layers.
        /// fmap :: (a -> b) -> t a -> t b
        /// - Parameter fn: Transformation of the innermost value.
        /// - Returns: The stack with the transformed value.
        func map<B: Sendable>(
            _ fn: @escaping @Sendable (A) -> B
        ) -> \(target) {
            \(target)(\(mapBody))
        }

        /// Curried, point-free form of ``map(_:)``.
        /// fmap :: (a -> b) -> t a -> t b
        /// - Parameter fn: Transformation of the innermost value.
        /// - Returns: A function mapping `fn` over a stack.
        static func fmap<B: Sendable>(
            _ fn: @escaping @Sendable (A) -> B
        ) -> @Sendable (\(self_)) -> \(target) {
            { $0.map(fn) }
        }
    }
    """
}

func applicativeExtension(_ stack: Stack) -> String {
    let selfA = stack.applied("A")
    let selfB = stack.applied("B")
    let fnStack = stack.applied("@Sendable (Input) -> A")
    let inputStack = stack.applied("Input")
    let lhsType = stack.applied("A1")
    let rhsType = stack.applied("A2")
    // A Reader is re-runnable but an AsyncStream is single-pass: build the stream inside each run,
    // or every run after the first would see an exhausted stream.
    let readerStreamPure = stack.outer == .reader && stack.inner == .asyncStream
        ? "Reader { (_: Env) in AsyncStream.just(value) }" // `const(…)` would build one stream eagerly
        : nil
    let pure = stack.customPure ?? readerStreamPure ?? stack.outer.outerPure(
        stack.outer == .publisher || stack.outer == .asyncStream
            ? (stack.inner == .asyncStream ? "AsyncStream.just(value)" : "I.pure(value)")
            : (stack.inner == .asyncStream ? "AsyncStream.just(value)" : ".pure(value)")
    )
    let liftA2Body = indentTail(
        stack.customLiftA2.map { "\(selfA)(\n\(indent($0))\n)" }
            ?? "\(selfA)(liftA2\(stack.infix)(fn)(lhs.rawValue, rhs.rawValue))",
        by: 3
    )
    let applyBody = stack.applyViaLiftA2
        ? "\(selfA).liftA2 { (function: @Sendable (Input) -> A, input: Input) in function(input) }(ff, fa)"
        : "\(selfA)(apply\(stack.infix)(ff.rawValue, fa.rawValue))"
    let seqRightBody = stack.customLiftA2 != nil
        ? "\(selfB).liftA2 { (_: A, right: B) in right }(self, rhs)"
        : "\(selfB)(seqRight\(stack.infix)(rawValue, rhs.rawValue))"
    let seqLeftBody = stack.customLiftA2 != nil
        ? "\(selfA).liftA2 { (left: A, _: B) in left }(self, rhs)"
        : "\(selfA)(seqLeft\(stack.infix)(rawValue, rhs.rawValue))"
    return """
    // MARK: - Applicative

    \(availabilityPrefix(stack))public extension \(stack.name)\(stack.memberWhere) {
        /// Lifts a value into both layers.
        /// pure :: a -> t a
        /// - Parameter value: The value to lift.
        /// - Returns: The minimal stack holding `value`.
        static func pure(_ value: A) -> \(selfA) {
            \(selfA)(\(pure))
        }

        /// Applies the functions inside a stack to the values inside another.
        /// (<*>) :: t (a -> b) -> t a -> t b
        /// - Parameters:
        ///   - ff: The stack of functions.
        ///   - fa: The stack of arguments.
        /// - Returns: The stack of results.
        static func apply<Input: Sendable>(
            _ ff: \(fnStack),
            _ fa: \(inputStack)
        ) -> \(selfA) {
            \(applyBody)
        }

        /// Lifts a binary function to work on two stacks.
        /// liftA2 :: (a1 -> a2 -> a) -> t a1 -> t a2 -> t a
        /// - Parameter fn: The binary function.
        /// - Returns: A function combining two stacks with `fn`.
        static func liftA2<A1: Sendable, A2: Sendable>(
            _ fn: @escaping @Sendable (A1, A2) -> A
        ) -> @Sendable (\(lhsType), \(rhsType)) -> \(selfA) {
            { lhs, rhs in
                \(liftA2Body)
            }
        }

        /// Sequences two stacks, keeping the right result.
        /// (*>) :: t a -> t b -> t b
        /// - Parameter rhs: The stack whose result is kept.
        /// - Returns: The combined stack.
        func seqRight<B: Sendable>(
            _ rhs: \(selfB)
        ) -> \(selfB) {
            \(seqRightBody)
        }

        /// Sequences two stacks, keeping the left result.
        /// (<*) :: t a -> t b -> t a
        /// - Parameter rhs: The stack whose result is discarded.
        /// - Returns: The combined stack.
        func seqLeft<B: Sendable>(
            _ rhs: \(selfB)
        ) -> \(selfA) {
            \(seqLeftBody)
        }
    }
    """
}

func monadExtension(_ stack: Stack) -> String {
    let selfA = stack.applied("A")
    let selfB = stack.applied("B")
    let flatMapBody = stack.customFlatMap
        ?? (stack.freeFlatMap
            ? "flatMapT\(stack.infix)(rawValue) { fn($0).rawValue }"
            : "rawValue.flatMapT { fn($0).rawValue }")
    return """
    // MARK: - Monad

    \(availabilityPrefix(stack))public extension \(stack.name)\(stack.memberWhere) {
        /// Monadic bind over the whole stack.
        /// (>>=) :: t a -> (a -> t b) -> t b
        /// - Parameter fn: Continuation returning the next stack.
        /// - Returns: The bound stack.
        func flatMap<B: Sendable>(
            _ fn: @escaping @Sendable (A) -> \(selfB)
        ) -> \(selfB) {
            \(selfB)(\(flatMapBody))
        }

        /// Curried, point-free form of ``flatMap(_:)``.
        /// (=<<) :: (a -> t b) -> t a -> t b
        /// - Parameter fn: Continuation returning the next stack.
        /// - Returns: A function binding a stack to `fn`.
        static func bind<B: Sendable>(
            _ fn: @escaping @Sendable (A) -> \(selfB)
        ) -> @Sendable (\(selfA)) -> \(selfB) {
            { $0.flatMap(fn) }
        }

        /// Kleisli composition (left-to-right).
        /// (>=>) :: (a0 -> t a) -> (a -> t b) -> a0 -> t b
        /// - Parameters:
        ///   - fn1: The first step.
        ///   - fn2: The second step.
        /// - Returns: The composed step.
        static func kleisli<A0, B: Sendable>(
            _ fn1: @escaping @Sendable (A0) -> \(selfA),
            _ fn2: @escaping @Sendable (A) -> \(selfB)
        ) -> @Sendable (A0) -> \(selfB) {
            { fn1($0).flatMap(fn2) }
        }

        /// Kleisli composition (right-to-left).
        /// (<=<) :: (a -> t b) -> (a0 -> t a) -> a0 -> t b
        /// - Parameters:
        ///   - fn2: The second step.
        ///   - fn1: The first step.
        /// - Returns: The composed step.
        static func kleisliBack<A0, B: Sendable>(
            _ fn2: @escaping @Sendable (A) -> \(selfB),
            _ fn1: @escaping @Sendable (A0) -> \(selfA)
        ) -> @Sendable (A0) -> \(selfB) {
            { fn1($0).flatMap(fn2) }
        }
    }
    """
}

func liftExtension(_ stack: Stack) -> String {
    let lift = stack.outer.lift
    let shape = stack.inner.shape
    let elem = lift.elem
    let args = lift.ctx + shape.ctx.map { "\(elem).\($0)" } + ["\(elem).\(shape.value)"]
    let target = "\(stack.name)<\(args.joined(separator: ", "))>"
    // Publisher isn't one of our shape protocols; the existential erasure needs a Sendable metatype.
    var conditions = ["\(elem): \(stack.inner == .publisher ? "Publisher & SendableMetatype" : shape.proto)"]
    for (param, arg) in zip(stack.params, args) where param.constraint == "Sendable" {
        conditions.append("\(arg): Sendable")
    }
    let conversion: String = switch (stack.outer, stack.inner) {
    case (_, .publisher):
        // Implicitly erases the concrete publisher to the `any Publisher` the stack stores.
        lift.convert("").replacingOccurrences(of: "(\(elem).)", with: " { $0 }")
    case (.nonEmpty, _):
        // Spelled with its type arguments: inside `extension NonEmpty`, a bare `NonEmpty` means `Self`.
        "NonEmpty<\(stack.inner.type(around: args.last ?? "", Array(args.dropLast()), asInner: true))>"
            + "(head: \(elem).\(shape.convert)(head), tail: \(elem).coerceArray(tail))"
    default:
        lift.convert(shape.convert)
    }
    return """
    // MARK: - Lifting

    \(availabilityPrefix(stack))public extension \(lift.ext) where \(conditions.joined(separator: ", ")) {
        /// Lifts this nested value into the ``\(stack.name)`` stack (O(1), no copy).
        var \(stack.outer.liftName): \(target) {
            \(target)(\(conversion))
        }
    }
    """
}

// MARK: - Operator file

func operatorFile(_ stack: Stack) -> String {
    let avail = availabilityPrefix(stack)
    let ctx = stack.params.dropLast().map(\.sendableDeclaration)
    let valueConstraint = stack.params.last?.constraint ?? "Sendable"
    func generics(_ names: [String]) -> String {
        (ctx + names.map { "\($0): \(valueConstraint)" }).joined(separator: ", ")
    }
    func kleisliGenerics() -> String { (ctx + ["A0", "A: \(valueConstraint)", "B: \(valueConstraint)"]).joined(separator: ", ") }
    let fa = stack.applied("A")
    let fb = stack.applied("B")
    let tag = stack.name
    var ops: [String] = []
    ops.append("""
    /// (<$>) :: (a -> b) -> \(tag) a -> \(tag) b
    \(avail)public func <£> <\(generics(["A", "B"]))>(
        _ fn: @escaping @Sendable (A) -> B,
        _ fa: \(fa)
    ) -> \(fb) {
        fa.map(fn)
    }

    /// (<&>) :: \(tag) a -> (a -> b) -> \(tag) b
    \(avail)public func <&> <\(generics(["A", "B"]))>(
        _ fa: \(fa),
        _ fn: @escaping @Sendable (A) -> B
    ) -> \(fb) {
        fn <£> fa
    }

    /// ($>) :: \(tag) a -> b -> \(tag) b
    \(avail)public func £> <\(generics(["A", "B"]))>(
        _ fa: \(fa),
        _ value: B
    ) -> \(fb) {
        fa.map(const(value))
    }

    /// (<$) :: b -> \(tag) a -> \(tag) b
    \(avail)public func <£ <\(generics(["A", "B"]))>(
        _ value: B,
        _ fa: \(fa)
    ) -> \(fb) {
        fa £> value
    }
    """)
    if stack.kind != .functor {
        ops.append("""
        /// (<*>) :: \(tag) (a -> b) -> \(tag) a -> \(tag) b
        \(avail)public func <*> <\(generics(["A", "B"]))>(
            _ ff: \(stack.applied("@Sendable (A) -> B")),
            _ fa: \(fa)
        ) -> \(fb) {
            \(fb).apply(ff, fa)
        }

        /// (*>) :: \(tag) a -> \(tag) b -> \(tag) b
        \(avail)public func *> <\(generics(["A", "B"]))>(
            _ lhs: \(fa),
            _ rhs: \(fb)
        ) -> \(fb) {
            lhs.seqRight(rhs)
        }

        /// (<*) :: \(tag) a -> \(tag) b -> \(tag) a
        \(avail)public func <* <\(generics(["A", "B"]))>(
            _ lhs: \(fa),
            _ rhs: \(fb)
        ) -> \(fa) {
            lhs.seqLeft(rhs)
        }
        """)
    }
    if stack.kind == .monad {
        ops.append("""
        /// (>>=) :: \(tag) a -> (a -> \(tag) b) -> \(tag) b
        \(avail)public func >>- <\(generics(["A", "B"]))>(
            _ fa: \(fa),
            _ fn: @escaping @Sendable (A) -> \(fb)
        ) -> \(fb) {
            fa.flatMap(fn)
        }

        /// (=<<) :: (a -> \(tag) b) -> \(tag) a -> \(tag) b
        \(avail)public func -<< <\(generics(["A", "B"]))>(
            _ fn: @escaping @Sendable (A) -> \(fb),
            _ fa: \(fa)
        ) -> \(fb) {
            fa >>- fn
        }

        /// (>=>) :: (a0 -> \(tag) a) -> (a -> \(tag) b) -> a0 -> \(tag) b
        \(avail)public func >=> <\(kleisliGenerics())>(
            _ fn1: @escaping @Sendable (A0) -> \(fa),
            _ fn2: @escaping @Sendable (A) -> \(fb)
        ) -> @Sendable (A0) -> \(fb) {
            \(fa).kleisli(fn1, fn2)
        }

        /// (<=<) :: (a -> \(tag) b) -> (a0 -> \(tag) a) -> a0 -> \(tag) b
        \(avail)public func <=< <\(kleisliGenerics())>(
            _ fn2: @escaping @Sendable (A) -> \(fb),
            _ fn1: @escaping @Sendable (A0) -> \(fa)
        ) -> @Sendable (A0) -> \(fb) {
            fn1 >=> fn2
        }
        """)
    }
    let imports = stack.isCore ? ["CoreFP"] : ["CoreFP", "CoreFPOperators", "DataStructure"]
    return wrapCombine(stack, imports: imports, body: ops.joined(separator: "\n\n"))
}

// MARK: - Main

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let fileManager = FileManager.default

func generatedDirectory(_ module: String) -> URL {
    root.appendingPathComponent("Sources/\(module)/Transformer/Generated", isDirectory: true)
}

let names = inventory.map(\.name)
if Set(names).count != names.count {
    FileHandle.standardError.write(Data("Duplicate stack in inventory\n".utf8))
    exit(1)
}

for module in ["CoreFP", "DataStructure", "CoreFPOperators", "DataStructureOperators"] {
    let directory = generatedDirectory(module)
    try? fileManager.removeItem(at: directory)
    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
}

for stack in inventory {
    let structURL = generatedDirectory(stack.module).appendingPathComponent("\(stack.name).swift")
    try structFile(stack).write(to: structURL, atomically: true, encoding: .utf8)
    let operatorURL = generatedDirectory(stack.operatorModule).appendingPathComponent("\(stack.name)+Operators.swift")
    try operatorFile(stack).write(to: operatorURL, atomically: true, encoding: .utf8)
}

print("Generated \(inventory.count) transformer stacks.")
