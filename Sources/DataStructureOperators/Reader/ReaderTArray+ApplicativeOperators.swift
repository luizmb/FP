import CoreFPOperators
import DataStructure
import Foundation

// ReaderT + Array

// (<*>) :: Reader e [(a -> b)] -> Reader e [a] -> Reader e [b]
public func <*> <Env, A, B>(
    _ readerF: Reader<Env, [@Sendable (A) -> B]>,
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
