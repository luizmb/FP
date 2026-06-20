// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

/// A type that holds either a value of type `A` (`.left`) or a value of type `B` (`.right`).
///
/// `Either<A, B>` is the canonical sum type (disjoint union / coproduct) in this library.
/// It is commonly used to represent:
///
/// - Computations with two distinct outcomes (e.g. success/failure, left/right routing).
/// - Error handling with a typed error channel (similar to `Result`, but symmetric — neither
///   side is semantically "error" or "success").
///
/// ## Key differences from Result and Validation
///
/// | Type | Error accumulation | Short-circuit |
/// |------|--------------------|---------------|
/// | `Result<S, E>` | No (left = error, right = success) | Yes — first error wins |
/// | `Either<A, B>` | No | Yes — first `.left` wins in monadic chain |
/// | ``Validation``<E, A> | Yes — errors combine via ``Semigroup`` | No |
///
/// Use `Either` when you want a purely structural sum type with no implied semantics.
/// Use `Result` for Swift error-handling conventions. Use ``Validation`` when you need
/// to accumulate all errors.
///
/// ## Creating Either values
///
/// ```swift
/// let left: Either<String, Int> = .left("error")
/// let right: Either<String, Int> = .right(42)
/// ```
///
/// ## Consuming Either values
///
/// ```swift
/// let result = either.match(
///     caseLeft:  { "left: \($0)" },
///     caseRight: { "right: \($0)" }
/// )
/// ```
///
/// ## Functor / Monad
///
/// `Either` is a `Functor`, `Applicative`, and `Monad` on the right type parameter:
///
/// ```swift
/// let mapped: Either<String, String> = right.map { String($0) }
/// let flatMapped = right.flatMap { n in n > 0 ? .right(n) : .left("negative") }
///
/// // Operator forms (requires DataStructureOperators):
/// let mapped2 = { String($0) } <£> right
/// let chained = right >>- { n in n > 0 ? .right(n) : .left("negative") }
/// ```
///
/// ## Interoperability
///
/// `Either` can be converted to and from `Result` via the extensions in `Either+Result.swift`,
/// and swapped via ``inverted()``.
///
/// ## Prism support
///
/// Each case has a corresponding `Prism` via the `Either.prism` namespace, plus
/// per-case accessors (`either.left`, `either.right`) via `@dynamicMemberLookup`. The
/// `Either.Cases` enum lets you ask `either.is(.left)` / `.is(.right)` for a uniform
/// predicate over the case names. See `Either+Prism.swift`.
///
/// - SeeAlso: ``Validation``, ``SumType2``, `Result`
public enum Either<A, B>: SumType2 {
    /// The left case — by convention, often used for errors or "alternative" values.
    case left(A)
    /// The right case — by convention, often used for the primary "success" value.
    case right(B)
}

public extension Either {
    /// Declaration.
    func match<C>(caseLeft: (A) -> C, caseRight: (B) -> C) -> C {
        switch self {
        case let .left(left):
            caseLeft(left)

        case let .right(right):
            caseRight(right)
        }
    }
}

extension Either: Equatable where A: Equatable, B: Equatable {}
extension Either: Comparable where A: Comparable, B: Comparable {}
extension Either: Hashable where A: Hashable, B: Hashable {}
extension Either: Decodable where A: Decodable, B: Decodable {}
extension Either: Encodable where A: Encodable, B: Encodable {}
extension Either: Sendable where A: Sendable, B: Sendable {}
extension Either: Error where A: Error, B: Error {}

extension Either: CustomStringConvertible where A: CustomStringConvertible, B: CustomStringConvertible {
    public var description: String {
        match(
            caseLeft: { ".left(\($0.description))" },
            caseRight: { ".right(\($0.description))" }
        )
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Either: Identifiable where A: Identifiable, B: Identifiable, A.ID == B.ID {
    public var id: A.ID {
        match(caseLeft: \.id, caseRight: \.id)
    }
}
