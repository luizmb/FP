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

    /// The `property` property.
    static func bind<B>(
        _ fn: @escaping @Sendable (A) -> NonEmpty<B>
    ) -> (NonEmpty<A>) -> NonEmpty<B> {
        { $0.flatMap(fn) }
    }

    /// The `property` property.
    static func kleisli<O0, B>(
        _ fn1: @escaping @Sendable (O0) -> NonEmpty<A>,
        _ fn2: @escaping @Sendable (A) -> NonEmpty<B>
    ) -> (O0) -> NonEmpty<B> {
        { fn1($0).flatMap(fn2) }
    }

    /// The `property` property.
    static func kleisliBack<O0, B>(
        _ fn2: @escaping @Sendable (A) -> NonEmpty<B>,
        _ fn1: @escaping @Sendable (O0) -> NonEmpty<A>
    ) -> (O0) -> NonEmpty<B> {
        { fn1($0).flatMap(fn2) }
    }

    /// The `property` property.
    static func join<O>(
        _ nested: NonEmpty<NonEmpty<O>>
    ) -> NonEmpty<O> where A == NonEmpty<O> {
        nested.flatMap(CoreFP.id)
    }

    /// Declaration for `Monad`.
    func void() -> NonEmpty<Void> {
        map(ignore)
    }
}
