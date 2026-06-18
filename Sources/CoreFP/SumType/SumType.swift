// SPDX-License-Identifier: Apache-2.0
/// A two-case sum type (coproduct) that can be eliminated via pattern matching.
///
/// `SumType2` is the abstract interface shared by ``Either``, `Optional` (implicitly),
/// `Result`, and `Validation`. It provides a uniform `match` eliminator that covers both
/// cases without requiring `switch` statements.
///
/// ## Conforming types
///
/// | Type | Left case | Right case |
/// |------|-----------|------------|
/// | `Either<A, B>` | `.left(A)` | `.right(B)` |
/// | `Result<S, E>` | `.failure(E)` | `.success(S)` |
/// | `Validation<E, A>` | `.failure(E)` | `.success(A)` |
/// | `Optional<A>` | `.none` | `.some(A)` |
///
/// ## Convenience accessors
///
/// The default extension provides:
/// - `a`: returns the left value if present, `nil` otherwise.
/// - `b`: returns the right value if present, `nil` otherwise.
/// - `isA`: `true` when in the left case.
/// - `isB`: `true` when in the right case.
///
/// ```swift
/// let e: Either<String, Int> = .right(42)
/// e.a       // nil
/// e.b       // Optional(42)
/// e.isA     // false
/// e.isB     // true
/// ```
///
/// - SeeAlso: ``Either``, ``Validation``
public protocol SumType2<A, B>: Sendable {
    associatedtype A
    associatedtype B

    static func left(_ a: A) -> Self
    static func right(_ b: B) -> Self

    /// Eliminates the sum type by applying one of two functions.
    ///
    /// This is the canonical way to consume a `SumType2` value without pattern matching.
    ///
    /// ```swift
    /// let value: Either<String, Int> = .right(42)
    /// let result = value.match(caseLeft: { "error: \($0)" }, caseRight: { "value: \($0)" })
    /// // "value: 42"
    /// ```
    func match<C>(caseLeft: (A) -> C, caseRight: (B) -> C) -> C
}

public extension SumType2 {
    /// The `property` property.
    static func from(_ another: any SumType2<A, B>) -> Self {
        another.match(caseLeft: Self.left, caseRight: Self.right)
    }
}

public extension SumType2 {
    /// The `property` property.
    static func match<ST1: SumType2, ST2: SumType2, C>(
        _ st1: ST1,
        _ st2: ST2,
        caseLeftLeft: (ST1.A, ST2.A) -> C,
        caseLeftRight: (ST1.A, ST2.B) -> C,
        caseRightLeft: (ST1.B, ST2.A) -> C,
        caseRightRight: (ST1.B, ST2.B) -> C
    ) -> C {
        st1.match { left1 in
            st2.match { left2 in
                caseLeftLeft(left1, left2)
            } caseRight: { right2 in
                caseLeftRight(left1, right2)
            }
        } caseRight: { right1 in
            st2.match { left2 in
                caseRightLeft(right1, left2)
            } caseRight: { right2 in
                caseRightRight(right1, right2)
            }
        }
    }
}

public extension SumType2 {
    /// Declaration.
    var a: A? { match(caseLeft: Optional.some, caseRight: const(nil)) }
    /// Declaration.
    var b: B? { match(caseLeft: const(nil), caseRight: Optional.some) }

    /// Declaration.
    var isA: Bool { match(caseLeft: const(true), caseRight: const(false)) }
    /// Declaration.
    var isB: Bool { match(caseLeft: const(false), caseRight: const(true)) }
}
