// SPDX-License-Identifier: Apache-2.0
public extension Array {
    /// Returns the Cartesian product of two arrays — every element from `first` paired with every
    /// element from `second`, ordered by the outer-then-inner iteration.
    ///
    /// ```swift
    /// Array.cartesian([1, 3, 5], ["a", "b"])
    /// // [(1, "a"), (1, "b"),
    /// //  (3, "a"), (3, "b"),
    /// //  (5, "a"), (5, "b")]
    /// ```
    ///
    /// This is distinct from `zip`, which only pairs elements at matching indices. The Cartesian
    /// product preserves all `n × m` combinations.
    ///
    /// Functionally equivalent to the list-applicative `liftA2(fn)` on two arrays when `fn` is
    /// tuple construction — provided here as a dedicated overload for clarity and to keep the
    /// tuple output without going through a closure.
    static func cartesian<A, B>(_ first: [A], _ second: [B]) -> [(A, B)] where Element == (A, B) {
        first.flatMap { a in second.map { b in (a, b) } }
    }

    /// Returns the 3-ary Cartesian product of three arrays. Result size is `first.count * second.count * third.count`.
    ///
    /// ```swift
    /// Array.cartesian([1, 2], ["a"], [true, false])
    /// // [(1, "a", true), (1, "a", false),
    /// //  (2, "a", true), (2, "a", false)]
    /// ```
    static func cartesian<A, B, C>(
        _ first: [A],
        _ second: [B],
        _ third: [C]
    ) -> [(A, B, C)] where Element == (A, B, C) {
        first.flatMap { a in
            second.flatMap { b in
                third.map { c in (a, b, c) }
            }
        }
    }

    /// Returns the 4-ary Cartesian product of four arrays.
    static func cartesian<A, B, C, D>(
        _ first: [A],
        _ second: [B],
        _ third: [C],
        _ fourth: [D]
    ) -> [(A, B, C, D)] where Element == (A, B, C, D) {
        first.flatMap { a in
            second.flatMap { b in
                third.flatMap { c in
                    fourth.map { d in (a, b, c, d) }
                }
            }
        }
    }
}
