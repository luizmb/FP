// NonEmptyTEither: outer = NonEmpty, inner = Either
// Type: NonEmpty<Either<L, A>>

public extension NonEmpty {
    /// mapT for NonEmpty<Either<L, A>> — maps over the Right values, preserves Lefts.
    func mapT<L, Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> NonEmpty<Either<L, B>>
    where A == Either<L, Inner> {
        map { $0.mapRight(fn) }
    }

    static func fmapT<L, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (NonEmpty<Either<L, Inner>>) -> NonEmpty<Either<L, B>> {
        { $0.mapT(fn) }
    }
}
