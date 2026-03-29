import CoreFP

// EitherTNonEmpty: outer = Either, inner = NonEmpty
// Type: Either<L, NonEmpty<A>>

/// flatMapT for Either<L, NonEmpty<A>>.
/// .left(l)    → .left(l)
/// .right(ne)  → apply fn element-wise; short-circuit on first Left, combine Rights.
public func flatMapTEitherNonEmpty<L, A, B>(
    _ either: Either<L, NonEmpty<A>>,
    _ fn: @escaping (A) -> Either<L, NonEmpty<B>?>
) -> Either<L, NonEmpty<B>?> {
    either.flatMap { ne in
        var accumulated: NonEmpty<B>?
        for element in ne.toArray {
            switch fn(element) {
            case .left(let l): return .left(l)
            case .right(let nbOpt):
                if let nb = nbOpt {
                    accumulated = accumulated.map { NonEmpty.combine($0, nb) } ?? nb
                }
            }
        }
        return .right(accumulated)
    }
}

/// Curried version
public func bindTEitherNonEmpty<L, A, B>(
    _ fn: @escaping (A) -> Either<L, NonEmpty<B>?>
) -> (Either<L, NonEmpty<A>>) -> Either<L, NonEmpty<B>?> {
    { flatMapTEitherNonEmpty($0, fn) }
}
