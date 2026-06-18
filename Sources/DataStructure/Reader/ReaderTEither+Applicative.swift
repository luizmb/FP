// SPDX-License-Identifier: Apache-2.0
import Foundation

// ReaderT + Either

/// Apply for ReaderT Either
public func applyReaderEither<Env: Sendable, L: Sendable, A: Sendable, B: Sendable>(
    _ readerF: Reader<Env, Either<L, @Sendable (A) -> B>>,
    _ readerA: Reader<Env, Either<L, A>>
) -> Reader<Env, Either<L, B>> {
    Reader { @Sendable env in
        readerF(env).flatMap { @Sendable f in readerA(env).mapRight(f) }
    }
}

/// liftA2 for ReaderT Either
public func liftA2ReaderEither<Env, L, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Reader<Env, Either<L, A>>, Reader<Env, Either<L, B>>) -> Reader<Env, Either<L, C>> {
    { readerA, readerB in
        Reader { env in
            Either.liftA2(fn)(readerA(env), readerB(env))
        }
    }
}

/// seqRight for ReaderT Either
public func seqRightReaderEither<Env, L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: Reader<Env, Either<L, A>>,
    _ rhs: Reader<Env, Either<L, B>>
) -> Reader<Env, Either<L, B>> {
    Reader { @Sendable env in lhs(env).seqRight(rhs(env)) }
}

/// seqLeft for ReaderT Either
public func seqLeftReaderEither<Env, L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: Reader<Env, Either<L, A>>,
    _ rhs: Reader<Env, Either<L, B>>
) -> Reader<Env, Either<L, A>> {
    Reader { @Sendable env in lhs(env).seqLeft(rhs(env)) }
}
