// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension These {
    /// Monadic bind operation for These
    /// Requires `A: Semigroup` — a `.both` continuing into another `.this`/`.both` merges
    /// the accumulated `A` payloads.
    ///
    /// ```haskell
    /// This  a   >>= _ = This a
    /// That  x   >>= k = k x
    /// These a x >>= k = case k x of
    ///   This  b   -> This  (a <> b)
    ///   That  y   -> These a y
    ///   These b y -> These (a <> b) y
    /// ```
    ///
    /// (>>=) :: m a -> (a -> m b) -> m b
    func flatMap<C>(
        _ fn: @escaping @Sendable (B) -> These<A, C>
    ) -> These<A, C> where A: Semigroup {
        switch self {
        case let .this(a):
            .this(a)

        case let .that(b):
            fn(b)

        case let .both(a, b):
            switch fn(b) {
            case let .this(b1):
                .this(A.combine(a, b1))

            case let .that(c):
                .both(a, c)

            case let .both(b1, c):
                .both(A.combine(a, b1), c)
            }
        }
    }

    /// Curried version of flatMap for functional composition
    /// (>>=) :: m a -> (a -> m b) -> m b
    static func bind<C>(
        _ fn: @escaping @Sendable (B) -> These<A, C>
    ) -> (These<A, B>) -> These<A, C> where A: Semigroup {
        { these in
            these.flatMap(fn)
        }
    }

    /// Kleisli composition (left-to-right)
    /// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
    static func kleisli<B0, C>(
        _ fn1: @escaping @Sendable (B0) -> These<A, B>,
        _ fn2: @escaping @Sendable (B) -> These<A, C>
    ) -> (B0) -> These<A, C> where A: Semigroup {
        { b0 in
            fn1(b0).flatMap(fn2)
        }
    }

    /// Kleisli composition (right-to-left)
    /// (<=<) :: (b -> m c) -> (a -> m b) -> a -> m c
    static func kleisliBack<B0, C>(
        _ fn2: @escaping @Sendable (B) -> These<A, C>,
        _ fn1: @escaping @Sendable (B0) -> These<A, B>
    ) -> (B0) -> These<A, C> where A: Semigroup {
        { b0 in
            fn1(b0).flatMap(fn2)
        }
    }

    /// Monadic join - flattens nested These
    /// join :: m (m a) -> m a
    static func join<B1>(
        _ nested: These<A, These<A, B1>>
    ) -> These<A, B1> where B == These<A, B1>, A: Semigroup {
        nested.flatMap(CoreFP.id)
    }
}
