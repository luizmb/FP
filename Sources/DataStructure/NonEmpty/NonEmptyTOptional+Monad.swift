// SPDX-License-Identifier: Apache-2.0
// NonEmptyTOptional: outer = NonEmpty, inner = Optional
// Type: NonEmpty<A?>

extension NonEmpty {
    /// flatMapT for NonEmpty<A?> — maps over present values, preserves nil slots.
    /// nil  → nil
    /// some → NonEmpty<B?> (inner flatMap)
    func flatMapT<Inner, B>(_ fn: (Inner) -> NonEmpty<B?>) -> NonEmpty<B?> where A == Inner? {
        flatMap { element -> NonEmpty<B?> in
            guard let inner = element else { return NonEmpty<B?>(head: nil) }
            return fn(inner)
        }
    }

    /// The `property` property.
    static func bindT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> NonEmpty<B?>
    ) -> @Sendable (NonEmpty<Inner?>) -> NonEmpty<B?> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `NonEmptyT + Optional` (left-to-right)
/// (>=>) :: (a -> NonEmpty<b?>) -> (b -> NonEmpty<c?>) -> a -> NonEmpty<c?>
func kleisliT<A, B, C>(
    _ fn1: @escaping @Sendable (A) -> NonEmpty<B?>,
    _ fn2: @escaping @Sendable (B) -> NonEmpty<C?>
) -> @Sendable (A) -> NonEmpty<C?> {
    { a in fn1(a).flatMapT(fn2) }
}
