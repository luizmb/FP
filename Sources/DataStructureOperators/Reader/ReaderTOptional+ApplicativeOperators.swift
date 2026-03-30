import CoreFPOperators
import DataStructure
import Foundation

// ReaderT + Optional

// (<*>) :: Reader e (Optional<(a -> b)>) -> Reader e (Optional<a>) -> Reader e (Optional<b>)
public func <*> <Env, A, B>(
    _ readerF: Reader<Env, ((A) -> B)?>,
    _ readerA: Reader<Env, A?>
) -> Reader<Env, B?> {
    applyReaderOptional(readerF, readerA)
}

// (*>) :: Reader e (Optional<a>) -> Reader e (Optional<b>) -> Reader e (Optional<b>)
public func *> <Env, A, B>(
    _ lhs: Reader<Env, A?>,
    _ rhs: Reader<Env, B?>
) -> Reader<Env, B?> {
    seqRightReaderOptional(lhs, rhs)
}

// (<*) :: Reader e (Optional<a>) -> Reader e (Optional<b>) -> Reader e (Optional<a>)
public func <* <Env, A, B>(
    _ lhs: Reader<Env, A?>,
    _ rhs: Reader<Env, B?>
) -> Reader<Env, A?> {
    seqLeftReaderOptional(lhs, rhs)
}
