// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension SumType2 {
    /// Fold both cases of the sum type into a single value `C`.
    ///
    /// This is an alias for ``SumType2/match(caseLeft:caseRight:)`` with Haskell's `bifoldMap`
    /// argument order (left function first) and no labels, like `Validation.bifoldMap(_:_:)`.
    ///
    /// ```swift
    /// let e: Either<String, Int> = .right(42)
    /// let s = e.bifoldMap({ "error: \($0)" }, { "value: \($0)" })
    /// // "value: 42"
    /// ```
    func bifoldMap<C>(
        _ lf: (A) -> C,
        _ rf: (B) -> C
    ) -> C {
        match(caseLeft: lf, caseRight: rf)
    }

    /// Extracts the left value, or returns `otherwise` if in the right case.
    ///
    /// ```swift
    /// Either<Int, String>.left(1).fromLeft(0)    // 1
    /// Either<Int, String>.right("x").fromLeft(0) // 0
    /// ```
    func fromLeft(_ otherwise: A) -> A {
        match(caseLeft: id, caseRight: const(otherwise))
    }

    /// Extracts the right value, or returns `otherwise` if in the left case.
    ///
    /// ```swift
    /// Either<Int, String>.right("x").fromRight("")   // "x"
    /// Either<Int, String>.left(1).fromRight("")      // ""
    /// ```
    func fromRight(_ otherwise: B) -> B {
        match(caseLeft: const(otherwise), caseRight: id)
    }
}
