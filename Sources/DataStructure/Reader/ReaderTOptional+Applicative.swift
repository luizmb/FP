import CoreFP
import Foundation

// ReaderT + Optional

/// Apply for ReaderT Optional
/// (<*>) :: Reader e (a -> b) -> Reader e a -> Reader e b
public func applyReaderOptional<Env, A, B>(
    _ readerF: Reader<Env, (@Sendable (A) -> B)?>,
    _ readerA: Reader<Env, A?>
) -> Reader<Env, B?> {
    Reader { env in
        guard let fn = readerF(env), let a = readerA(env) else {
            return nil
        }
        return fn(a)
    }
}

/// liftA2 for ReaderT Optional
public func liftA2ReaderOptional<Env, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (Reader<Env, A?>, Reader<Env, B?>) -> Reader<Env, C?> {
    { readerA, readerB in
        Reader { env in
            guard let a = readerA(env), let b = readerB(env) else {
                return nil
            }
            return fn(a, b)
        }
    }
}

/// seqRight for ReaderT Optional
public func seqRightReaderOptional<Env, A, B>(
    _ lhs: Reader<Env, A?>,
    _ rhs: Reader<Env, B?>
) -> Reader<Env, B?> {
    Reader { env in lhs(env).seqRight(rhs(env)) }
}

/// seqLeft for ReaderT Optional
public func seqLeftReaderOptional<Env, A, B>(
    _ lhs: Reader<Env, A?>,
    _ rhs: Reader<Env, B?>
) -> Reader<Env, A?> {
    Reader { env in lhs(env).seqLeft(rhs(env)) }
}
