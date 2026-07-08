// SPDX-License-Identifier: Apache-2.0

// MARK: - Functor

public extension NonEmpty {
    /// Transform every element — structure preserved, contents changed.
    func map<B>(_ fn: (A) -> B) -> NonEmpty<B> {
        NonEmpty<B>(head: fn(head), tail: tail.map(fn))
    }

    /// Curried, point-free form of ``map(_:)``.
    /// fmap :: (a -> b) -> NonEmpty a -> NonEmpty b
    static func fmap<B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (NonEmpty<A>) -> NonEmpty<B> {
        { $0.map(fn) }
    }
}

// MARK: - Free functions

/// Transforms every element of a `NonEmpty` — free-function form of ``NonEmpty/map(_:)``.
/// fmap :: (a -> b) -> NonEmpty a -> NonEmpty b
public func fmap<A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ ne: NonEmpty<A>
) -> NonEmpty<B> {
    ne.map(fn)
}
