// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import Foundation

// ReaderT + Either

/// (<*>) :: Reader e (Either l (a -> b)) -> Reader e (Either l a) -> Reader e (Either l b)
public func <*> <Env: Sendable, L: Sendable, A: Sendable, B: Sendable>(
    _ readerF: Reader<Env, Either<L, @Sendable (A) -> B>>,
    _ readerA: Reader<Env, Either<L, A>>
) -> Reader<Env, Either<L, B>> {
    applyReaderEither(readerF, readerA)
}

/// (*>) :: Reader e (Either l a) -> Reader e (Either l b) -> Reader e (Either l b)
public func *> <Env: Sendable, L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: Reader<Env, Either<L, A>>,
    _ rhs: Reader<Env, Either<L, B>>
) -> Reader<Env, Either<L, B>> {
    seqRightReaderEither(lhs, rhs)
}

/// (<*) :: Reader e (Either l a) -> Reader e (Either l b) -> Reader e (Either l a)
public func <* <Env: Sendable, L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: Reader<Env, Either<L, A>>,
    _ rhs: Reader<Env, Either<L, B>>
) -> Reader<Env, Either<L, A>> {
    seqLeftReaderEither(lhs, rhs)
}
