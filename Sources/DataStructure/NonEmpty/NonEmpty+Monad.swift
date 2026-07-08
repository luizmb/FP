// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - Monad

public extension NonEmpty {
    /// Map each element to a NonEmpty, then concatenate all results.
    /// Result is always non-empty because fn(head) is non-empty.
    func flatMap<B>(_ fn: (A) -> NonEmpty<B>) -> NonEmpty<B> {
        let headResult = fn(head)
        let tailResults = tail.flatMap { fn($0).toArray }
        return NonEmpty<B>(head: headResult.head, tail: headResult.tail + tailResults)
    }

    /// Curried, point-free form of ``flatMap(_:)``.
    /// (>>=) :: NonEmpty a -> (a -> NonEmpty b) -> NonEmpty b
    static func bind<B>(
        _ fn: @escaping @Sendable (A) -> NonEmpty<B>
    ) -> (NonEmpty<A>) -> NonEmpty<B> {
        { $0.flatMap(fn) }
    }

    /// Kleisli composition (left-to-right) for `NonEmpty`-producing functions.
    /// (>=>) :: (o0 -> NonEmpty a) -> (a -> NonEmpty b) -> o0 -> NonEmpty b
    static func kleisli<O0, B>(
        _ fn1: @escaping @Sendable (O0) -> NonEmpty<A>,
        _ fn2: @escaping @Sendable (A) -> NonEmpty<B>
    ) -> (O0) -> NonEmpty<B> {
        { fn1($0).flatMap(fn2) }
    }

    /// Kleisli composition (right-to-left) for `NonEmpty`-producing functions.
    /// (<=<) :: (a -> NonEmpty b) -> (o0 -> NonEmpty a) -> o0 -> NonEmpty b
    static func kleisliBack<O0, B>(
        _ fn2: @escaping @Sendable (A) -> NonEmpty<B>,
        _ fn1: @escaping @Sendable (O0) -> NonEmpty<A>
    ) -> (O0) -> NonEmpty<B> {
        { fn1($0).flatMap(fn2) }
    }

    /// Flattens a nested `NonEmpty`, concatenating every inner `NonEmpty` in order.
    /// join :: NonEmpty (NonEmpty a) -> NonEmpty a
    static func join<O>(
        _ nested: NonEmpty<NonEmpty<O>>
    ) -> NonEmpty<O> where A == NonEmpty<O> {
        nested.flatMap(CoreFP.id)
    }

    /// Discards every element's value, keeping only the structure (and its length).
    /// void :: NonEmpty a -> NonEmpty ()
    func void() -> NonEmpty<Void> {
        map(ignore)
    }
}
