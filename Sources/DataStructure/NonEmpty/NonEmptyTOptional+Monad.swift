// SPDX-License-Identifier: Apache-2.0
// NonEmptyTOptional: outer = NonEmpty, inner = Optional
// Type: NonEmpty<A?>

public extension NonEmpty {
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
    ) -> (NonEmpty<Inner?>) -> NonEmpty<B?> {
        { $0.flatMapT(fn) }
    }
}
