import Foundation
import Core

// EitherTArray: outer = Either, inner = Array
// Type: Either<L, [A]> = Either<L, Array<A>>

/// apply for EitherTArray: Either<L, [(A->B)]> -> Either<L, [A]> -> Either<L, [B]>
public func applyEitherArray<L, A, B>(
    _ fns: Either<L, [(A) -> B]>,
    _ values: Either<L, [A]>
) -> Either<L, [B]> {
    Either.liftA2(Array.apply)(fns, values)
}

/// liftA2 for EitherTArray
public func liftA2EitherArray<L, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Either<L, [A]>, Either<L, [B]>) -> Either<L, [C]> {
    Either.liftA2(Array.liftA2(fn))
}

/// seqRight for EitherTArray
public func seqRightEitherArray<L, A, B>(
    _ lhs: Either<L, [A]>,
    _ rhs: Either<L, [B]>
) -> Either<L, [B]> {
    Either.liftA2({ (a: [A], b: [B]) in a.seqRight(b) })(lhs, rhs)
}

/// seqLeft for EitherTArray
public func seqLeftEitherArray<L, A, B>(
    _ lhs: Either<L, [A]>,
    _ rhs: Either<L, [B]>
) -> Either<L, [A]> {
    Either.liftA2({ (a: [A], b: [B]) in a.seqLeft(b) })(lhs, rhs)
}
