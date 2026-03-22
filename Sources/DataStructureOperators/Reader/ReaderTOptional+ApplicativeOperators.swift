import DataStructure
import Foundation
import Core
import CoreOperators

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
