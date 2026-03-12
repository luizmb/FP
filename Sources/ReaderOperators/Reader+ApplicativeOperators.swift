import FP
import Reader
import Foundation
import Operators

// (<*>) :: Reader e (a -> b) -> Reader e a -> Reader e b
public func <*> <Env, A, B>(
    _ readerF: Reader<Env, (A) -> B>,
    _ readerA: Reader<Env, A>
) -> Reader<Env, B> {
    Reader { env in
        let fn = readerF(env)
        let a = readerA(env)
        return fn(a)
    }
}

// (*>) :: Reader e a -> Reader e b -> Reader e b
public func *> <Env, A, B>(
    _ lhs: Reader<Env, A>,
    _ rhs: Reader<Env, B>
) -> Reader<Env, B> {
    Reader { env in
        _ = lhs(env)
        return rhs(env)
    }
}

// (<*) :: Reader e a -> Reader e b -> Reader e a
public func <* <Env, A, B>(
    _ lhs: Reader<Env, A>,
    _ rhs: Reader<Env, B>
) -> Reader<Env, A> {
    Reader { env in
        let a = lhs(env)
        _ = rhs(env)
        return a
    }
}
