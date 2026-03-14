import Foundation
import FP
import Reader
import Operators

// ReaderT + Optional

// (<*>) :: Reader e (Optional<(a -> b)>) -> Reader e (Optional<a>) -> Reader e (Optional<b>)
public func <*> <Env, A, B>(
    _ readerF: Reader<Env, Optional<(A) -> B>>,
    _ readerA: Reader<Env, Optional<A>>
) -> Reader<Env, Optional<B>> {
    applyReaderOptional(readerF, readerA)
}

// (*>) :: Reader e (Optional<a>) -> Reader e (Optional<b>) -> Reader e (Optional<b>)
public func *> <Env, A, B>(
    _ lhs: Reader<Env, Optional<A>>,
    _ rhs: Reader<Env, Optional<B>>
) -> Reader<Env, Optional<B>> {
    seqRightReaderOptional(lhs, rhs)
}

// (<*) :: Reader e (Optional<a>) -> Reader e (Optional<b>) -> Reader e (Optional<a>)
public func <* <Env, A, B>(
    _ lhs: Reader<Env, Optional<A>>,
    _ rhs: Reader<Env, Optional<B>>
) -> Reader<Env, Optional<A>> {
    seqLeftReaderOptional(lhs, rhs)
}

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

// ReaderT + Reader (nested)

// (<*>) :: Reader e1 (Reader e2 (a -> b)) -> Reader e1 (Reader e2 a) -> Reader e1 (Reader e2 b)
public func <*> <Env1, Env2, A, B>(
    _ readerF: Reader<Env1, Reader<Env2, (A) -> B>>,
    _ readerA: Reader<Env1, Reader<Env2, A>>
) -> Reader<Env1, Reader<Env2, B>> {
    applyReaderReader(readerF, readerA)
}

// (*>) :: Reader e1 (Reader e2 a) -> Reader e1 (Reader e2 b) -> Reader e1 (Reader e2 b)
public func *> <Env1, Env2, A, B>(
    _ lhs: Reader<Env1, Reader<Env2, A>>,
    _ rhs: Reader<Env1, Reader<Env2, B>>
) -> Reader<Env1, Reader<Env2, B>> {
    seqRightReaderReader(lhs, rhs)
}

// (<*) :: Reader e1 (Reader e2 a) -> Reader e1 (Reader e2 b) -> Reader e1 (Reader e2 a)
public func <* <Env1, Env2, A, B>(
    _ lhs: Reader<Env1, Reader<Env2, A>>,
    _ rhs: Reader<Env1, Reader<Env2, B>>
) -> Reader<Env1, Reader<Env2, A>> {
    seqLeftReaderReader(lhs, rhs)
}

// ReaderT + Array

// (<*>) :: Reader e [(a -> b)] -> Reader e [a] -> Reader e [b]
public func <*> <Env, A, B>(
    _ readerF: Reader<Env, [(A) -> B]>,
    _ readerA: Reader<Env, [A]>
) -> Reader<Env, [B]> {
    applyReaderArray(readerF, readerA)
}

// (*>) :: Reader e [a] -> Reader e [b] -> Reader e [b]
public func *> <Env, A, B>(
    _ lhs: Reader<Env, [A]>,
    _ rhs: Reader<Env, [B]>
) -> Reader<Env, [B]> {
    seqRightReaderArray(lhs, rhs)
}

// (<*) :: Reader e [a] -> Reader e [b] -> Reader e [a]
public func <* <Env, A, B>(
    _ lhs: Reader<Env, [A]>,
    _ rhs: Reader<Env, [B]>
) -> Reader<Env, [A]> {
    seqLeftReaderArray(lhs, rhs)
}
