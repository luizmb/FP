// SPDX-License-Identifier: Apache-2.0
// WriterTNonEmpty: outer = Writer, inner = NonEmpty
// Type: Writer<W, NonEmpty<A>>

public extension Writer {
    /// Declaration.
    func mapT<Inner, B>(_ fn: (Inner) -> B) -> Writer<W, NonEmpty<B>>
    where A == NonEmpty<Inner> {
        mapWriter { ne in ne.map(fn) }
    }

    /// The `property` property.
    static func fmapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Writer<W, NonEmpty<Inner>>) -> Writer<W, NonEmpty<B>>
    where A == NonEmpty<Inner> {
        { $0.mapT(fn) }
    }
}
