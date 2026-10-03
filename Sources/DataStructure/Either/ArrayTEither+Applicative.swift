// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// ArrayTEither: outer = Array, inner = Either
// Type: [Either<L,A>] = Array<Either<L,A>>
// Haskell: ExceptT l []
//
// The applicative is derived from the monad (`<*>` = `ap`): sequential and short-circuiting
// exactly like `flatMapT`. A `.left` on the left yields a single `.left` and never runs the right side.

/// apply for ArrayTEither
/// mf <*> ma = mf >>= \f -> fmap f ma
public func applyArrayEither<L: Sendable, A: Sendable, B: Sendable>(
    _ fns: [Either<L, @Sendable (A) -> B>],
    _ values: [Either<L, A>]
) -> [Either<L, B>] {
    fns.flatMapT { f in values.mapT(f) }
}

/// liftA2 for ArrayTEither
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
public func liftA2ArrayEither<L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> ([Either<L, A>], [Either<L, B>]) -> [Either<L, C>] {
    { arrA, arrB in
        arrA.flatMapT { a in arrB.mapT { b in fn(a, b) } }
    }
}

/// seqRight for ArrayTEither
/// ma *> mb = ma >>= \_ -> mb
public func seqRightArrayEither<L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: [Either<L, A>],
    _ rhs: [Either<L, B>]
) -> [Either<L, B>] {
    lhs.flatMapT { (_: A) in rhs }
}

/// seqLeft for ArrayTEither
/// ma <* mb = ma >>= \a -> fmap (const a) mb
public func seqLeftArrayEither<L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: [Either<L, A>],
    _ rhs: [Either<L, B>]
) -> [Either<L, A>] {
    lhs.flatMapT { a in rhs.mapT { (_: B) in a } }
}
