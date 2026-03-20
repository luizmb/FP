import Foundation
import FP
import Reader
import Either

// ReaderT + Either

/// Apply for ReaderT Either
public func applyReaderEither<Env, L, A, B>(
    _ readerF: Reader<Env, Either<L, (A) -> B>>,
    _ readerA: Reader<Env, Either<L, A>>
) -> Reader<Env, Either<L, B>> {
    Reader { env in
        readerF(env).flatMap(readerA(env).mapRight)
    }
}

/// liftA2 for ReaderT Either
public func liftA2ReaderEither<Env, L, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Reader<Env, Either<L, A>>, Reader<Env, Either<L, B>>) -> Reader<Env, Either<L, C>> {
    { readerA, readerB in
        Reader { env in
            Either.liftA2(fn)(readerA(env), readerB(env))
        }
    }
}

/// seqRight for ReaderT Either
public func seqRightReaderEither<Env, L, A, B>(
    _ lhs: Reader<Env, Either<L, A>>,
    _ rhs: Reader<Env, Either<L, B>>
) -> Reader<Env, Either<L, B>> {
    Reader { env in lhs(env).seqRight(rhs(env)) }
}

/// seqLeft for ReaderT Either
public func seqLeftReaderEither<Env, L, A, B>(
    _ lhs: Reader<Env, Either<L, A>>,
    _ rhs: Reader<Env, Either<L, B>>
) -> Reader<Env, Either<L, A>> {
    Reader { env in lhs(env).seqLeft(rhs(env)) }
}
