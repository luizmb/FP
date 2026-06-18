// SPDX-License-Identifier: Apache-2.0
// NonEmptyTOptional: outer = NonEmpty, inner = Optional
// Type: NonEmpty<A?>

public extension NonEmpty {
    /// mapT for NonEmpty<A?> — maps over the inner Optional values.
    func mapT<Inner, B>(_ fn: (Inner) -> B) -> NonEmpty<B?> where A == Inner? {
        map { $0.map(fn) }
    }

    /// The `property` property.
    static func fmapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (NonEmpty<Inner?>) -> NonEmpty<B?> {
        { $0.mapT(fn) }
    }
}
