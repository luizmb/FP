// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

/// A type that holds a value of type `A` (`.this`), a value of type `B` (`.that`), or
/// both (`.both`) — the classic "inclusive-or" sum type from Haskell's `these` package.
///
/// `These<A, B>` is commonly used to represent:
///
/// - Merging two sources of data (e.g. zipping two lists of unequal length) where either
///   side, or both, may be present.
/// - Aligning records by key, where a key may exist only on the left, only on the right,
///   or on both sides.
/// - Accumulating a running result (`A`) alongside a final value (`B`), where the running
///   result is optional until the final value is also produced.
///
/// ## Key differences from Either and Validation
///
/// | Type | Cases | Both sides at once? |
/// |------|-------|----------------------|
/// | ``Either``<A, B> | `.left(A)`, `.right(B)` | No — exactly one side |
/// | ``Validation``<E, A> | `.failure(E)`, `.success(A)` | No — exactly one side |
/// | `These<A, B>` | `.this(A)`, `.that(B)`, `.both(A, B)` | Yes — `.both` carries both |
///
/// Use `These` when a computation can genuinely produce *both* an `A` and a `B` at the
/// same time, not just one or the other. Use ``Either`` when the two outcomes are mutually
/// exclusive.
///
/// ## Creating These values
///
/// ```swift
/// let this: These<String, Int> = .this("only a")
/// let that: These<String, Int> = .that(42)
/// let both: These<String, Int> = .both("a", 42)
/// ```
///
/// ## Consuming These values
///
/// ```swift
/// let result = these.match(
///     caseThis: { "this: \($0)" },
///     caseThat: { "that: \($0)" },
///     caseBoth: { a, b in "both: \(a), \(b)" }
/// )
/// ```
///
/// ## Functor / Applicative / Monad
///
/// `These` is a `Functor` on the last type parameter `B`. Its `Applicative` and `Monad`
/// instances additionally require `A: Semigroup`, since combining two `.this`/`.both`
/// values must merge their `A` payloads rather than discard one:
///
/// ```swift
/// let mapped: These<String, String> = that.map { String($0) }
///
/// // Applicative / Monad require A: Semigroup (e.g. String, [String]):
/// let combined = These<String, Int>.liftA2(+)(both1, both2)
/// let chained = both.flatMap { n in n > 0 ? .that(n) : .this("negative") }
/// ```
///
/// ## Interoperability
///
/// `These` can be constructed from an `Either` via ``fromEither(_:)``, and from a pair of
/// optionals via ``align(_:_:)``. See `These+Either.swift`.
///
/// - SeeAlso: ``Either``, ``Validation``, ``Semigroup``
public enum These<A, B> {
    /// The "this" case — only `A` is present.
    case this(A)
    /// The "that" case — only `B` is present.
    case that(B)
    /// The "both" case — both `A` and `B` are present.
    case both(A, B)
}

public extension These {
    /// Declaration.
    func match<C>(caseThis: (A) -> C, caseThat: (B) -> C, caseBoth: (A, B) -> C) -> C {
        switch self {
        case let .this(a):
            caseThis(a)

        case let .that(b):
            caseThat(b)

        case let .both(a, b):
            caseBoth(a, b)
        }
    }
}

public extension These {
    /// The `A` payload, present for `.this` and `.both`; `nil` for `.that`.
    var this: A? {
        match(caseThis: Optional.some, caseThat: const(nil), caseBoth: { a, _ in a })
    }

    /// The `B` payload, present for `.that` and `.both`; `nil` for `.this`.
    var that: B? {
        match(caseThis: const(nil), caseThat: Optional.some, caseBoth: { _, b in b })
    }

    /// Declaration.
    var isThis: Bool {
        match(caseThis: const(true), caseThat: const(false), caseBoth: const(false))
    }

    /// Declaration.
    var isThat: Bool {
        match(caseThis: const(false), caseThat: const(true), caseBoth: const(false))
    }

    /// Declaration.
    var isBoth: Bool {
        match(caseThis: const(false), caseThat: const(false), caseBoth: const(true))
    }
}

extension These: Equatable where A: Equatable, B: Equatable {}
extension These: Hashable where A: Hashable, B: Hashable {}
extension These: Sendable where A: Sendable, B: Sendable {}
extension These: Decodable where A: Decodable, B: Decodable {}
extension These: Encodable where A: Encodable, B: Encodable {}

extension These: CustomStringConvertible where A: CustomStringConvertible, B: CustomStringConvertible {
    public var description: String {
        match(
            caseThis: { ".this(\($0.description))" },
            caseThat: { ".that(\($0.description))" },
            caseBoth: { ".both(\($0.description), \($1.description))" }
        )
    }
}
