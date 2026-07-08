// SPDX-License-Identifier: Apache-2.0
import CoreFP

/// A validation result that accumulates errors rather than short-circuiting.
///
/// `Validation<E, A>` is structurally similar to `Result<A, E>` but has a critically
/// different `Applicative` instance: when two `failure` cases are combined, their errors
/// are merged via ``Semigroup/combine(_:_:)`` rather than the first error winning.
/// This makes `Validation` the right choice whenever you want to collect *all* validation
/// errors from a form or data structure in a single pass.
///
/// ## Key differences from Either and Result
///
/// | Type | Error accumulation | Monad |
/// |------|--------------------|-------|
/// | `Result<S, E>` | No — first error wins | Yes |
/// | ``Either``<E, A> | No — first `.left` wins | Yes |
/// | `Validation<E, A>` | Yes — errors combine via `E: Semigroup` | No* |
///
/// *`Validation` is NOT a `Monad` — it has no lawful `flatMap`. Use it only for
/// validation pipelines that can run all checks independently. Convert to `Result`
/// or `Either` when you need monadic chaining.
///
/// ## Creating Validation values
///
/// ```swift
/// // Success:
/// let ok: Validation<[String], Int> = .success(42)
///
/// // Failure (a non-empty list of error messages):
/// let bad: Validation<[String], Int> = .failure(["must be positive"])
/// ```
///
/// ## Accumulating errors with Applicative
///
/// ```swift
/// let nameResult: Validation<[String], String> = validateName(input.name)
/// let ageResult:  Validation<[String], Int>    = validateAge(input.age)
///
/// // Both are run; all errors from both sides are collected:
/// let both: Validation<[String], (String, Int)> = Validation.zip(nameResult, ageResult)
/// // If name fails with ["too short"] and age fails with ["negative"],
/// // both fails with ["too short", "negative"].
///
/// // Operator form (requires DataStructureOperators):
/// let validated = { name, age in User(name: name, age: age) } <£> nameResult <*> ageResult
/// ```
///
/// ## Interoperability
///
/// - Convert to/from `Result`: see `Validation+Result.swift`.
/// - Convert to/from `Either`: see `Validation+Either.swift`.
///
/// ## Choosing the error type `E`
///
/// `E` must conform to ``Semigroup`` so errors can be combined. Common choices:
/// - `[ValidationError]` — array concatenation
/// - `NonEmpty<[ValidationError]>` — guaranteed non-empty error list
/// - `String` — concatenated error message
///
/// ## Prism support
///
/// Each case has a corresponding `Prism` via the `Validation.prism` namespace, plus
/// per-case accessors (`validation.failure`, `validation.success`) via
/// `@dynamicMemberLookup`. The `Validation.Cases` enum lets you ask
/// `validation.is(.failure)` / `.is(.success)` for a uniform predicate over the case
/// names. See `Validation+Prism.swift`.
///
/// - SeeAlso: ``Either``, ``NonEmpty``, ``Semigroup``
public enum Validation<E: Semigroup, A> {
    /// A failed validation with accumulated error(s).
    case failure(E)
    /// A successful validation result.
    case success(A)
}

public extension Validation {
    /// Eliminates a `Validation` by supplying a handler for each case, unifying both branches into a single result type.
    /// either :: (e -> c) -> (a -> c) -> Validation e a -> c
    /// - Parameters:
    ///   - caseFailure: Handler invoked with the accumulated errors when `self` is `.failure`.
    ///   - caseSuccess: Handler invoked with the wrapped value when `self` is `.success`.
    /// - Returns: The result of applying whichever handler corresponds to the current case.
    func match<C>(caseFailure: (E) -> C, caseSuccess: (A) -> C) -> C {
        switch self {
        case let .failure(e):
            caseFailure(e)

        case let .success(a):
            caseSuccess(a)
        }
    }
}

extension Validation: Equatable where E: Equatable, A: Equatable {}
extension Validation: Comparable where E: Comparable, A: Comparable {
    public static func < (lhs: Validation<E, A>, rhs: Validation<E, A>) -> Bool {
        switch (lhs, rhs) {
        case let (.failure(e1), .failure(e2)):
            e1 < e2

        case let (.success(a1), .success(a2)):
            a1 < a2

        case (.failure, .success):
            true

        case (.success, .failure):
            false
        }
    }
}

extension Validation: Hashable where E: Hashable, A: Hashable {}
extension Validation: Sendable where E: Sendable, A: Sendable {}
extension Validation: Decodable where E: Decodable, A: Decodable {}
extension Validation: Encodable where E: Encodable, A: Encodable {}
extension Validation: Error where E: Error, A: Error {}

extension Validation: CustomStringConvertible where E: CustomStringConvertible, A: CustomStringConvertible {
    public var description: String {
        match(
            caseFailure: { ".failure(\($0.description))" },
            caseSuccess: { ".success(\($0.description))" }
        )
    }
}
