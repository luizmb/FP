// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - Comonad

public extension NonEmpty {
    /// extract :: NonEmpty a -> a
    /// The current focus — the head element.
    var extract: A { head }

    /// extend :: (NonEmpty a -> b) -> NonEmpty a -> NonEmpty b
    /// Apply `f` to every suffix of `self` (the "list comonad restricted to non-empty lists").
    func extend<B>(_ f: (NonEmpty<A>) -> B) -> NonEmpty<B> {
        duplicate.map(f)
    }

    /// coflatMap is extend with arguments in the more familiar (value-first) order.
    func coflatMap<B>(_ f: (NonEmpty<A>) -> B) -> NonEmpty<B> {
        extend(f)
    }

    /// duplicate :: NonEmpty a -> NonEmpty (NonEmpty a)
    /// Builds the `NonEmpty` of all suffixes of `self`: `self` itself, then the
    /// `NonEmpty` starting at the second element, and so on down to the last element alone.
    /// Laws: extract . duplicate = id
    ///       fmap extract . duplicate = id
    var duplicate: NonEmpty<NonEmpty<A>> {
        let suffixes = (0 ..< tail.count).map { index in
            NonEmpty(head: tail[index], tail: Array(tail[(index + 1)...]))
        }
        return NonEmpty<NonEmpty<A>>(head: self, tail: suffixes)
    }

    /// Curried static form for point-free use.
    static func extend<B>(
        _ f: @escaping @Sendable (NonEmpty<A>) -> B
    ) -> (NonEmpty<A>) -> NonEmpty<B> {
        { $0.extend(f) }
    }
}

// MARK: - Free functions

/// extract :: NonEmpty a -> a
public func extract<A>(_ ne: NonEmpty<A>) -> A {
    ne.extract
}

/// extend :: (NonEmpty a -> b) -> NonEmpty a -> NonEmpty b
public func extend<A: Sendable, B: Sendable>(
    _ f: @escaping @Sendable (NonEmpty<A>) -> B
) -> (NonEmpty<A>) -> NonEmpty<B> {
    { $0.extend(f) }
}

/// duplicate :: NonEmpty a -> NonEmpty (NonEmpty a)
public func duplicate<A>(_ ne: NonEmpty<A>) -> NonEmpty<NonEmpty<A>> {
    ne.duplicate
}
