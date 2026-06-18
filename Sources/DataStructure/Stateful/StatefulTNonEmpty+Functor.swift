// SPDX-License-Identifier: Apache-2.0
// StatefulTNonEmpty: outer = Stateful, inner = NonEmpty
// Type: Stateful<S, NonEmpty<A>>

public extension Stateful {
    /// Declaration.
    func mapT<Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Stateful<S, NonEmpty<B>>
    where A == NonEmpty<Inner> {
        mapStateful { ne in ne.map(fn) }
    }

    /// The `property` property.
    static func fmapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Stateful<S, NonEmpty<Inner>>) -> Stateful<S, NonEmpty<B>>
    where A == NonEmpty<Inner> {
        { $0.mapT(fn) }
    }
}
