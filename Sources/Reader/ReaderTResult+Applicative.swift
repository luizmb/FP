import Foundation
import FP

// ReaderT + Result

/// Apply for ReaderT Result
public func applyReaderResult<Env, A, B, E: Error>(
    _ readerF: Reader<Env, Result<(A) -> B, E>>,
    _ readerA: Reader<Env, Result<A, E>>
) -> Reader<Env, Result<B, E>> {
    Reader { env in
        readerF(env).flatMap(readerA(env).map)
    }
}

/// liftA2 for ReaderT Result
public func liftA2ReaderResult<Env, A, B, C, E: Error>(
    _ fn: @escaping (A, B) -> C
) -> (Reader<Env, Result<A, E>>, Reader<Env, Result<B, E>>) -> Reader<Env, Result<C, E>> {
    { readerA, readerB in
        Reader { env in
            Result.liftA2(fn)(readerA(env), readerB(env))
        }
    }
}

/// seqRight for ReaderT Result
public func seqRightReaderResult<Env, A, B, E: Error>(
    _ lhs: Reader<Env, Result<A, E>>,
    _ rhs: Reader<Env, Result<B, E>>
) -> Reader<Env, Result<B, E>> {
    Reader { env in lhs(env).seqRight(rhs(env)) }
}

/// seqLeft for ReaderT Result
public func seqLeftReaderResult<Env, A, B, E: Error>(
    _ lhs: Reader<Env, Result<A, E>>,
    _ rhs: Reader<Env, Result<B, E>>
) -> Reader<Env, Result<A, E>> {
    Reader { env in lhs(env).seqLeft(rhs(env)) }
}
