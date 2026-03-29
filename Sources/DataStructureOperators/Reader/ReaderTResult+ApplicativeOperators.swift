import CoreFP
import CoreFPOperators
import DataStructure
import Foundation

// ReaderT + Result

// (<*>) :: Reader e (Result<(a -> b), e>) -> Reader e (Result<a, e>) -> Reader e (Result<b, e>)
public func <*> <Env, A, B, E: Error>(
    _ readerF: Reader<Env, Result<(A) -> B, E>>,
    _ readerA: Reader<Env, Result<A, E>>
) -> Reader<Env, Result<B, E>> {
    applyReaderResult(readerF, readerA)
}

// (*>) :: Reader e (Result<a, e>) -> Reader e (Result<b, e>) -> Reader e (Result<b, e>)
public func *> <Env, A, B, E: Error>(
    _ lhs: Reader<Env, Result<A, E>>,
    _ rhs: Reader<Env, Result<B, E>>
) -> Reader<Env, Result<B, E>> {
    seqRightReaderResult(lhs, rhs)
}

// (<*) :: Reader e (Result<a, e>) -> Reader e (Result<b, e>) -> Reader e (Result<a, e>)
public func <* <Env, A, B, E: Error>(
    _ lhs: Reader<Env, Result<A, E>>,
    _ rhs: Reader<Env, Result<B, E>>
) -> Reader<Env, Result<A, E>> {
    seqLeftReaderResult(lhs, rhs)
}
