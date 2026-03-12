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
        readerF(env).flatMap { fn in
            readerA(env).mapRight(fn)
        }
    }
}

/// liftA2 for ReaderT Either
public func liftA2ReaderEither<Env, L, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Reader<Env, Either<L, A>>, Reader<Env, Either<L, B>>) -> Reader<Env, Either<L, C>> {
    { readerA, readerB in
        Reader { env in
            readerA(env).flatMap { a in
                readerB(env).mapRight { b in
                    fn(a, b)
                }
            }
        }
    }
}
