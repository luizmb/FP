// MARK: - Functor

public extension NonEmpty {
    /// Transform every element — structure preserved, contents changed.
    func map<B>(_ fn: (A) -> B) -> NonEmpty<B> {
        NonEmpty<B>(head: fn(head), tail: tail.map(fn))
    }

    static func fmap<B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (NonEmpty<A>) -> NonEmpty<B> {
        { $0.map(fn) }
    }
}

// MARK: - Free functions

public func fmap<A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ ne: NonEmpty<A>
) -> NonEmpty<B> {
    ne.map(fn)
}
