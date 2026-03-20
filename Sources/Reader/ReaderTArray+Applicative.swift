import Foundation
import FP

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

/// seqRight for ReaderT Array
public func seqRightReaderArray<Env, A, B>(
    _ lhs: Reader<Env, [A]>,
    _ rhs: Reader<Env, [B]>
) -> Reader<Env, [B]> {
    Reader { env in lhs(env).seqRight(rhs(env)) }
}

/// seqLeft for ReaderT Array
public func seqLeftReaderArray<Env, A, B>(
    _ lhs: Reader<Env, [A]>,
    _ rhs: Reader<Env, [B]>
) -> Reader<Env, [A]> {
    Reader { env in lhs(env).seqLeft(rhs(env)) }
}
