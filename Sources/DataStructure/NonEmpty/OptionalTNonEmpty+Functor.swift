
// OptionalTNonEmpty: outer = Optional, inner = NonEmpty
// Type: NonEmpty<A>?

public extension Optional {
    /// mapT for NonEmpty<A>? — maps over the inner NonEmpty when present.
    func mapT<A, B>(_ fn: @escaping (A) -> B) -> NonEmpty<B>? where Wrapped == NonEmpty<A> {
        map { $0.map(fn) }
    }

    static func fmapT<A, B>(_ fn: @escaping (A) -> B) -> (NonEmpty<A>?) -> NonEmpty<B>? {
        { opt in opt.mapT(fn) }
    }
}
