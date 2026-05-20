import CoreFP

// ReaderTValidation: outer = Reader, inner = Validation
// Type: Reader<Env, Validation<E, A>>

public extension Reader {
    func mapT<E: Semigroup, Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Reader<Environment, Validation<E, B>>
    where Output == Validation<E, Inner> {
        mapReader(Validation<E, Inner>.fmap(fn))
    }

    static func fmapT<E: Semigroup, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Reader<Environment, Validation<E, Inner>>) -> Reader<Environment, Validation<E, B>>
    where Output == Validation<E, Inner> {
        { $0.mapT(fn) }
    }
}
