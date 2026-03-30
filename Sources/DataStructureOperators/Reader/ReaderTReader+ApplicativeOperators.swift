import CoreFPOperators
import DataStructure
import Foundation

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
