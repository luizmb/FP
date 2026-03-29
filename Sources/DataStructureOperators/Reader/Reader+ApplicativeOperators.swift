import CoreFP
import CoreFPOperators
import DataStructure
import Foundation

// (<*>) :: Reader<e, (a -> b)> -> Reader<e, a> -> Reader<e, b>
public func <*> <Env, A, B>(
    _ readerF: Reader<Env, (A) -> B>,
    _ readerA: Reader<Env, A>
) -> Reader<Env, B> {
    Reader<Env, B>.apply(readerF, readerA)
}

// (*>) :: Reader<e, a> -> Reader<e, b> -> Reader<e, b>
public func *> <Env, A, B>(
    _ lhs: Reader<Env, A>,
    _ rhs: Reader<Env, B>
) -> Reader<Env, B> {
    lhs.seqRight(rhs)
}

// (<*) :: Reader<e, a> -> Reader<e, b> -> Reader<e, a>
public func <* <Env, A, B>(
    _ lhs: Reader<Env, A>,
    _ rhs: Reader<Env, B>
) -> Reader<Env, A> {
    lhs.seqLeft(rhs)
}
