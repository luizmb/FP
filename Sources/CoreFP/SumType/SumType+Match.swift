import Foundation

public extension SumType2 {
    /// Fold both cases of the sum type into a single value `C`.
    ///
    /// This is an alias for ``SumType2/match(caseLeft:caseRight:)`` with labelled parameters,
    /// matching the Haskell `bimap` / bifoldMap naming convention.
    ///
    /// ```swift
    /// let e: Either<String, Int> = .right(42)
    /// let s = e.bifoldMap(leftBy: { "error: \($0)" }, rightBy: { "value: \($0)" })
    /// // "value: 42"
    /// ```
    func bifoldMap<C>(
        leftBy lf: (A) -> C,
        rightBy rf: (B) -> C
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
