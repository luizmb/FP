// SPDX-License-Identifier: Apache-2.0
// EitherTNonEmpty: outer = Either, inner = NonEmpty
// Type: Either<L, NonEmpty<A>>

/// flatMapT for Either<L, NonEmpty<A>>.
/// .left(l)    → .left(l)
/// .right(ne)  → apply fn element-wise; short-circuit on first Left, combine Rights.
public func flatMapTEitherNonEmpty<L, A, B>(
    _ either: Either<L, NonEmpty<A>>,
    _ fn: @escaping @Sendable (A) -> Either<L, NonEmpty<B>?>
) -> Either<L, NonEmpty<B>?> {
    either.flatMap { ne in
        var collected: [NonEmpty<B>] = []
        for element in ne.toArray {
            switch fn(element) {
            case let .left(l):
                return .left(l)

            case let .right(nbOpt):
                if let nb = nbOpt { collected.append(nb) }
            }
        }
        return .right(collected.first.map { NonEmpty.sconcat($0, Array(collected.dropFirst())) })
    }
}

/// Curried version
public func bindTEitherNonEmpty<L, A, B>(
    _ fn: @escaping @Sendable (A) -> Either<L, NonEmpty<B>?>
) -> @Sendable (Either<L, NonEmpty<A>>) -> Either<L, NonEmpty<B>?> {
    { flatMapTEitherNonEmpty($0, fn) }
}

/// Kleisli composition for `EitherT + NonEmpty` (left-to-right)
/// (>=>) :: (a -> Either<l, NonEmpty<b>?>) -> (b -> Either<l, NonEmpty<c>?>) -> a -> Either<l, NonEmpty<c>?>
public func kleisliT<L, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Either<L, NonEmpty<B>?>,
    _ fn2: @escaping @Sendable (B) -> Either<L, NonEmpty<C>?>
) -> @Sendable (A) -> Either<L, NonEmpty<C>?> {
    { a in
        fn1(a).flatMap { nbOpt in
            guard let nb = nbOpt else { return .right(nil) }
            return flatMapTEitherNonEmpty(.right(nb), fn2)
        }
    }
}
