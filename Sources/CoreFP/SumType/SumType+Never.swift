// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension SumType2 where B == Never {
    /// Extracts the only possible value when the right case is `Never` (uninhabited).
    ///
    /// When `B == Never`, the right case is impossible to construct, so the sum type
    /// is effectively isomorphic to its left type `A`. `value` performs this unwrapping
    /// safely using ``absurd(_:)`` for the impossible branch.
    ///
    /// ```swift
    /// let e: Either<Int, Never> = .left(42)
    /// e.value   // 42
    /// ```
    var value: A {
        match(caseLeft: id, caseRight: absurd)
    }

    /// Constructs the sum type from the only reachable case.
    ///
    /// When `B == Never`, only `.left` can be constructed. This initialiser wraps
    /// the value in `.left` for clarity in generic contexts.
    init(lifting value: A) {
        self = .left(value)
    }
}

public extension SumType2 where A == Never {
    /// Extracts the only possible value when the left case is `Never` (uninhabited).
    ///
    /// When `A == Never`, the left case is impossible to construct, so the sum type
    /// is effectively isomorphic to its right type `B`.
    ///
    /// ```swift
    /// let e: Either<Never, String> = .right("hello")
    /// e.value   // "hello"
    /// ```
    var value: B {
        match(caseLeft: absurd, caseRight: id)
    }

    /// Constructs the sum type from the only reachable case.
    ///
    /// When `A == Never`, only `.right` can be constructed.
    init(lifting value: B) {
        self = .right(value)
    }
}
