import CoreFP
import Foundation

// ArrayTEither: outer = Array, inner = Either
// Type: [Either<L,A>] = Array<Either<L,A>>

/// apply for ArrayTEither
public func applyArrayEither<L, A, B>(
    _ fns: [Either<L, (A) -> B>],
    _ values: [Either<L, A>]
) -> [Either<L, B>] {
    Array.liftA2(Either.apply)(fns, values)
}

/// liftA2 for ArrayTEither
public func liftA2ArrayEither<L, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> ([Either<L, A>], [Either<L, B>]) -> [Either<L, C>] {
    { arrA, arrB in
        Array.liftA2(Either.liftA2(fn))(arrA, arrB)
    }
}

/// seqRight for ArrayTEither
public func seqRightArrayEither<L, A, B>(
    _ lhs: [Either<L, A>],
    _ rhs: [Either<L, B>]
) -> [Either<L, B>] {
    Array.liftA2({ (a: Either<L, A>, b: Either<L, B>) in a.seqRight(b) })(lhs, rhs)
}

/// seqLeft for ArrayTEither
public func seqLeftArrayEither<L, A, B>(
    _ lhs: [Either<L, A>],
    _ rhs: [Either<L, B>]
) -> [Either<L, A>] {
    Array.liftA2({ (a: Either<L, A>, b: Either<L, B>) in a.seqLeft(b) })(lhs, rhs)
}
