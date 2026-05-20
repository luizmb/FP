import CoreFP

// WriterTValidation: outer = Writer, inner = Validation
// Type: Writer<W, Validation<E, A>>

public extension Writer {
    func mapT<E: Semigroup, Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Writer<W, Validation<E, B>>
    where A == Validation<E, Inner> {
        mapWriter(Validation<E, Inner>.fmap(fn))
    }

    static func fmapT<E: Semigroup, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Writer<W, Validation<E, Inner>>) -> Writer<W, Validation<E, B>>
    where A == Validation<E, Inner> {
        { $0.mapT(fn) }
    }
}
