import CoreFP
import Foundation

// OptionalTEither: outer = Optional, inner = Either
// Type: Either<L,A>? = Optional<Either<L,A>>

/// apply for OptionalTEither: Either<L,(A->B)>? -> Either<L,A>? -> Either<L,B>?
public func applyOptionalEither<L: Sendable, A: Sendable, B: Sendable>(
    _ fns: Either<L, @Sendable (A) -> B>?,
    _ values: Either<L, A>?
) -> Either<L, B>? {
    fns.flatMap { ef in values.map { ea in Either.apply(ef, ea) } }
}

/// liftA2 for OptionalTEither
public func liftA2OptionalEither<L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Either<L, A>?, Either<L, B>?) -> Either<L, C>? {
    Optional.liftA2(Either.liftA2(fn))
}

/// seqRight for OptionalTEither
public func seqRightOptionalEither<L: Sendable, A: Sendable, B: Sendable>(_ lhs: Either<L, A>?, _ rhs: Either<L, B>?) -> Either<L, B>? {
    lhs.seqRight(rhs)
}

/// seqLeft for OptionalTEither
public func seqLeftOptionalEither<L: Sendable, A: Sendable, B: Sendable>(_ lhs: Either<L, A>?, _ rhs: Either<L, B>?) -> Either<L, A>? {
    lhs.seqLeft(rhs)
}
