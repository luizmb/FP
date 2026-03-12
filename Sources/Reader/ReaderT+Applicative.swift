import Foundation
import FP

// ReaderT + Optional

/// Apply for ReaderT Optional
/// (<*>) :: Reader e (a -> b) -> Reader e a -> Reader e b
public func applyReaderOptional<Env, A, B>(
    _ readerF: Reader<Env, Optional<(A) -> B>>,
    _ readerA: Reader<Env, Optional<A>>
) -> Reader<Env, Optional<B>> {
    Reader { env in
        guard let fn = readerF(env), let a = readerA(env) else {
            return nil
        }
        return fn(a)
    }
}

/// liftA2 for ReaderT Optional
public func liftA2ReaderOptional<Env, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Reader<Env, A?>, Reader<Env, B?>) -> Reader<Env, C?> {
    { readerA, readerB in
        Reader { env in
            guard let a = readerA(env), let b = readerB(env) else {
                return nil
            }
            return fn(a, b)
        }
    }
}

// ReaderT + Result

/// Apply for ReaderT Result
public func applyReaderResult<Env, A, B, E: Error>(
    _ readerF: Reader<Env, Result<(A) -> B, E>>,
    _ readerA: Reader<Env, Result<A, E>>
) -> Reader<Env, Result<B, E>> {
    Reader { env in
        readerF(env).flatMap { fn in
            readerA(env).map(fn)
        }
    }
}

/// liftA2 for ReaderT Result
public func liftA2ReaderResult<Env, A, B, C, E: Error>(
    _ fn: @escaping (A, B) -> C
) -> (Reader<Env, Result<A, E>>, Reader<Env, Result<B, E>>) -> Reader<Env, Result<C, E>> {
    { readerA, readerB in
        Reader { env in
            readerA(env).flatMap { a in
                readerB(env).map { b in
                    fn(a, b)
                }
            }
        }
    }
}

// ReaderT + Reader (nested)

/// Apply for ReaderT Reader
public func applyReaderReader<Env1, Env2, A, B>(
    _ readerF: Reader<Env1, Reader<Env2, (A) -> B>>,
    _ readerA: Reader<Env1, Reader<Env2, A>>
) -> Reader<Env1, Reader<Env2, B>> {
    Reader { env1 in
        let innerF = readerF(env1)
        let innerA = readerA(env1)
        return Reader { env2 in
            let fn = innerF(env2)
            let a = innerA(env2)
            return fn(a)
        }
    }
}

/// liftA2 for ReaderT Reader
public func liftA2ReaderReader<Env1, Env2, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Reader<Env1, Reader<Env2, A>>, Reader<Env1, Reader<Env2, B>>) -> Reader<Env1, Reader<Env2, C>> {
    { readerA, readerB in
        Reader { env1 in
            let innerA = readerA(env1)
            let innerB = readerB(env1)
            return Reader { env2 in
                let a = innerA(env2)
                let b = innerB(env2)
                return fn(a, b)
            }
        }
    }
}

// ReaderT + Array

/// Apply for ReaderT Array
public func applyReaderArray<Env, A, B>(
    _ readerF: Reader<Env, [(A) -> B]>,
    _ readerA: Reader<Env, [A]>
) -> Reader<Env, [B]> {
    Reader { env in
        let fns = readerF(env)
        let values = readerA(env)
        return fns.flatMap { fn in
            values.map(fn)
        }
    }
}

/// liftA2 for ReaderT Array
public func liftA2ReaderArray<Env, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Reader<Env, [A]>, Reader<Env, [B]>) -> Reader<Env, [C]> {
    { readerA, readerB in
        Reader { env in
            let valuesA = readerA(env)
            let valuesB = readerB(env)
            return valuesA.flatMap { a in
                valuesB.map { b in
                    fn(a, b)
                }
            }
        }
    }
}
