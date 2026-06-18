// SPDX-License-Identifier: Apache-2.0
// EitherTNonEmpty: outer = Either, inner = NonEmpty
// Type: Either<L, NonEmpty<A>>

/// mapT for Either<L, NonEmpty<A>> — maps over NonEmpty inside Right, propagates Left.
public func mapTEitherNonEmpty<L, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ either: Either<L, NonEmpty<A>>
) -> Either<L, NonEmpty<B>> {
    either.mapRight { ne in ne.map(fn) }
}

/// Curried fmapT
public func fmapTEitherNonEmpty<L, A, B>(
    _ fn: @escaping @Sendable (A) -> B
) -> (Either<L, NonEmpty<A>>) -> Either<L, NonEmpty<B>> {
    { mapTEitherNonEmpty(fn, $0) }
}
