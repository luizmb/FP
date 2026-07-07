// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension These {
    /// Converts `Either<A, B>` to `These<A, B>`.
    ///
    /// Total and safe — no `Semigroup` constraint needed since there is no accumulation
    /// to perform. `.left` maps to `.this`, `.right` maps to `.that`.
    ///
    /// ```swift
    /// These<String, Int>.fromEither(.left("error"))   // .this("error")
    /// These<String, Int>.fromEither(.right(42))        // .that(42)
    /// ```
    static func fromEither(_ either: Either<A, B>) -> These<A, B> {
        either.match(caseLeft: These.this, caseRight: These.that)
    }

    /// Aligns two optionals into a single `These`, following Haskell's `Data.Align` "align".
    ///
    /// Returns `nil` only when both inputs are `nil`; otherwise produces `.this` when only
    /// `a` is present, `.that` when only `b` is present, and `.both` when both are present.
    ///
    /// ```swift
    /// These<String, Int>.align("a", 1)     // .both("a", 1)
    /// These<String, Int>.align("a", nil)   // .this("a")
    /// These<String, Int>.align(nil, 1)     // .that(1)
    /// These<String, Int>.align(nil, nil)   // nil
    /// ```
    static func align(_ a: A?, _ b: B?) -> These<A, B>? {
        switch (a, b) {
        case let (a?, b?):
            .both(a, b)

        case let (a?, nil):
            .this(a)

        case let (nil, b?):
            .that(b)

        case (nil, nil):
            nil
        }
    }
}
