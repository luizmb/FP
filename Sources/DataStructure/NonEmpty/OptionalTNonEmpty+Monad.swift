// OptionalTNonEmpty: outer = Optional, inner = NonEmpty
// Type: NonEmpty<A>?

public extension Optional {
    /// flatMapT for NonEmpty<A>? — nil short-circuits; some sequences the inner NonEmpty.
    /// nil       → nil
    /// some(ne)  → ne.flatMap(fn) wrapped back in Optional
    func flatMapT<A, B>(_ fn: @escaping (A) -> NonEmpty<B>?) -> NonEmpty<B>?
    where Wrapped == NonEmpty<A> {
        flatMap { ne in
            let results = ne.toArray.compactMap(fn)
            guard let first = results.first else { return nil }
            let combined = results.dropFirst().reduce(first, NonEmpty.combine)
            return combined
        }
    }

    static func bindT<A, B>(
        _ fn: @escaping (A) -> NonEmpty<B>?
    ) -> (NonEmpty<A>?) -> NonEmpty<B>? {
        { opt in opt.flatMapT(fn) }
    }
}
