import Foundation
import FP
import Reader
import Either
import Operators
import EitherOperators
import ReaderEither

// ReaderT + Either

// (<*>) :: Reader e (Either l (a -> b)) -> Reader e (Either l a) -> Reader e (Either l b)
public func <*> <Env, L, A, B>(
    _ readerF: Reader<Env, Either<L, (A) -> B>>,
    _ readerA: Reader<Env, Either<L, A>>
) -> Reader<Env, Either<L, B>> {
    applyReaderEither(readerF, readerA)
}

// (*>) :: Reader e (Either l a) -> Reader e (Either l b) -> Reader e (Either l b)
public func *> <Env, L, A, B>(
    _ lhs: Reader<Env, Either<L, A>>,
    _ rhs: Reader<Env, Either<L, B>>
) -> Reader<Env, Either<L, B>> {
    seqRightReaderEither(lhs, rhs)
}

// (<*) :: Reader e (Either l a) -> Reader e (Either l b) -> Reader e (Either l a)
public func <* <Env, L, A, B>(
    _ lhs: Reader<Env, Either<L, A>>,
    _ rhs: Reader<Env, Either<L, B>>
) -> Reader<Env, Either<L, A>> {
    seqLeftReaderEither(lhs, rhs)
}
