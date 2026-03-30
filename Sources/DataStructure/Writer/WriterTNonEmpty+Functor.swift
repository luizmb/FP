
// WriterTNonEmpty: outer = Writer, inner = NonEmpty
// Type: Writer<W, NonEmpty<A>>

public extension Writer {
    func mapT<Inner, B>(_ fn: (Inner) -> B) -> Writer<W, NonEmpty<B>>
    where A == NonEmpty<Inner> {
        mapWriter { ne in ne.map(fn) }
    }

    static func fmapT<Inner, B>(
        _ fn: @escaping (Inner) -> B
    ) -> (Writer<W, NonEmpty<Inner>>) -> Writer<W, NonEmpty<B>>
    where A == NonEmpty<Inner> {
        { $0.mapT(fn) }
    }
}
