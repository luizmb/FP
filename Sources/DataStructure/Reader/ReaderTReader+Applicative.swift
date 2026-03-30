import Foundation

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

/// seqRight for ReaderT Reader (nested)
public func seqRightReaderReader<Env1, Env2, A, B>(
    _ lhs: Reader<Env1, Reader<Env2, A>>,
    _ rhs: Reader<Env1, Reader<Env2, B>>
) -> Reader<Env1, Reader<Env2, B>> {
    liftA2ReaderReader { (_: A, b: B) in b }(lhs, rhs)
}

/// seqLeft for ReaderT Reader (nested)
public func seqLeftReaderReader<Env1, Env2, A, B>(
    _ lhs: Reader<Env1, Reader<Env2, A>>,
    _ rhs: Reader<Env1, Reader<Env2, B>>
) -> Reader<Env1, Reader<Env2, A>> {
    liftA2ReaderReader { (a: A, _: B) in a }(lhs, rhs)
}
