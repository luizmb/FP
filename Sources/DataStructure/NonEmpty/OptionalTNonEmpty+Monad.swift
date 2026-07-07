// SPDX-License-Identifier: Apache-2.0
// OptionalTNonEmpty: outer = Optional, inner = NonEmpty
// Type: NonEmpty<A>?

public extension Optional {
    /// flatMapT for NonEmpty<A>? — nil short-circuits; some sequences the inner NonEmpty.
    /// nil       → nil
    /// some(ne)  → ne.flatMap(fn) wrapped back in Optional
    func flatMapT<A, B>(_ fn: @escaping @Sendable (A) -> NonEmpty<B>?) -> NonEmpty<B>?
    where Wrapped == NonEmpty<A> {
        flatMap { ne in
            let results = ne.toArray.compactMap(fn)
            guard let first = results.first else { return nil }
            let combined = results.dropFirst().reduce(first, NonEmpty.combine)
            return combined
        }
    }

    /// The `property` property.
    static func bindT<A, B>(
        _ fn: @escaping @Sendable (A) -> NonEmpty<B>?
    ) -> (NonEmpty<A>?) -> NonEmpty<B>? {
        { opt in opt.flatMapT(fn) }
    }
}

/// Kleisli composition for `OptionalT + NonEmpty` (left-to-right)
/// (>=>) :: (a -> NonEmpty<b>?) -> (b -> NonEmpty<c>?) -> a -> NonEmpty<c>?
public func kleisliT<A, B, C>(
    _ fn1: @escaping @Sendable (A) -> NonEmpty<B>?,
    _ fn2: @escaping @Sendable (B) -> NonEmpty<C>?
) -> (A) -> NonEmpty<C>? {
    { a in fn1(a).flatMapT(fn2) }
}
