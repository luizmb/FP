// SPDX-License-Identifier: Apache-2.0
// MARK: - Functor

public extension NonEmpty {
    /// Transform every element — structure preserved, contents changed.
    func map<B>(_ fn: (A) -> B) -> NonEmpty<B> {
        NonEmpty<B>(head: fn(head), tail: tail.map(fn))
    }

    /// The `property` property.
    static func fmap<B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (NonEmpty<A>) -> NonEmpty<B> {
        { $0.map(fn) }
    }
}

// MARK: - Free functions

/// `fmap` for `Free functions`.
public func fmap<A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ ne: NonEmpty<A>
) -> NonEmpty<B> {
    ne.map(fn)
}
