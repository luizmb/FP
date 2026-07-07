// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension These {
    /// pure :: b -> These<a, b> — matches Haskell's `pure = That`.
    static func pure(_ value: B) -> These<A, B> where B: Sendable {
        .that(value)
    }

    /// apply :: These<a, (b -> c)> -> These<a, b> -> These<a, c>
    /// Requires `A: Semigroup` — combining two `.this`/`.both` payloads merges via `A.combine`.
    ///
    /// ```haskell
    /// pure = That
    /// This  a   <*> _         = This a
    /// That  _   <*> This  b   = This b
    /// That  f   <*> That  x   = That (f x)
    /// That  f   <*> These b x = These b (f x)
    /// These a _ <*> This  b   = This (a <> b)
    /// These a f <*> That  x   = These a (f x)
    /// These a f <*> These b x = These (a <> b) (f x)
    /// ```
    static func apply<C>(
        _ fnThese: These<A, @Sendable (B) -> C>,
        _ argThese: These<A, B>
    ) -> These<A, C> where A: Semigroup {
        switch (fnThese, argThese) {
        case let (.this(a), _):
            .this(a)

        case let (.that, .this(b)):
            .this(b)

        case let (.that(f), .that(x)):
            .that(f(x))

        case let (.that(f), .both(b, x)):
            .both(b, f(x))

        case let (.both(a, _), .this(b)):
            .this(A.combine(a, b))

        case let (.both(a, f), .that(x)):
            .both(a, f(x))

        case let (.both(a, f), .both(b, x)):
            .both(A.combine(a, b), f(x))
        }
    }

    /// liftA2 :: (b -> c -> d) -> These<a, b> -> These<a, c> -> These<a, d>
    static func liftA2<C, D>(
        _ fn: @escaping @Sendable (B, C) -> D
    ) -> @Sendable (These<A, B>, These<A, C>) -> These<A, D> where A: Semigroup, B: Sendable {
        { theseB, theseC in
            These<A, C>.apply(theseB.map { b in { @Sendable c in fn(b, c) } }, theseC)
        }
    }

    /// seqRight :: These<a, b> -> These<a, c> -> These<a, c>
    /// Run both, discard the left result, return the right — accumulating `A` via Semigroup.
    func seqRight<C>(_ rhs: These<A, C>) -> These<A, C> where A: Semigroup, B: Sendable {
        These<A, B>.liftA2 { _, c in c }(self, rhs)
    }

    /// seqLeft :: These<a, b> -> These<a, c> -> These<a, b>
    /// Run both, return the left result — accumulating `A` via Semigroup.
    func seqLeft<C>(_ rhs: These<A, C>) -> These<A, B> where A: Semigroup, B: Sendable {
        These<A, B>.liftA2 { b, _ in b }(self, rhs)
    }
}
