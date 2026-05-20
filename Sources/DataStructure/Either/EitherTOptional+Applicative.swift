import CoreFP
import Foundation

// EitherTOptional: outer = Either, inner = Optional
// Type: Either<L, A?> = Either<L, Optional<A>>

/// apply for EitherTOptional: Either<L,(A->B)?> -> Either<L,A?> -> Either<L,B?>
public func applyEitherOptional<L, A, B>(
    _ fns: Either<L, ((A) -> B)?>,
    _ values: Either<L, A?>
) -> Either<L, B?> {
    Either.liftA2(Optional.apply)(fns, values)
}

/// liftA2 for EitherTOptional
public func liftA2EitherOptional<L, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Either<L, A?>, Either<L, B?>) -> Either<L, C?> {
    Either.liftA2(Optional.liftA2(fn))
}

/// seqRight for EitherTOptional
public func seqRightEitherOptional<L, A, B>(
    _ lhs: Either<L, A?>,
    _ rhs: Either<L, B?>
) -> Either<L, B?> {
    Either.liftA2({ (a: A?, b: B?) in a.seqRight(b) })(lhs, rhs)
}

/// seqLeft for EitherTOptional
public func seqLeftEitherOptional<L, A, B>(
    _ lhs: Either<L, A?>,
    _ rhs: Either<L, B?>
) -> Either<L, A?> {
    Either.liftA2({ (a: A?, b: B?) in a.seqLeft(b) })(lhs, rhs)
}
