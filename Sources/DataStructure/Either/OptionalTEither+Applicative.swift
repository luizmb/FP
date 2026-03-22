import Foundation
import Core

// OptionalTEither: outer = Optional, inner = Either
// Type: Either<L,A>? = Optional<Either<L,A>>

/// apply for OptionalTEither: Either<L,(A->B)>? -> Either<L,A>? -> Either<L,B>?
public func applyOptionalEither<L, A, B>(
    _ fns: Either<L, (A) -> B>?,
    _ values: Either<L, A>?
) -> Either<L, B>? {
    fns.flatMap { ef in values.map { ea in Either.apply(ef, ea) } }
}

/// liftA2 for OptionalTEither
public func liftA2OptionalEither<L, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Either<L, A>?, Either<L, B>?) -> Either<L, C>? {
    Optional.liftA2(Either.liftA2(fn))
}

/// seqRight for OptionalTEither
public func seqRightOptionalEither<L, A, B>(_ lhs: Either<L, A>?, _ rhs: Either<L, B>?) -> Either<L, B>? {
    lhs.seqRight(rhs)
}

/// seqLeft for OptionalTEither
public func seqLeftOptionalEither<L, A, B>(_ lhs: Either<L, A>?, _ rhs: Either<L, B>?) -> Either<L, A>? {
    lhs.seqLeft(rhs)
}
