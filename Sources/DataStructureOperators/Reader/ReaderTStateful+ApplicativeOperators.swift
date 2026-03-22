import DataStructure
import CoreFPOperators
import CoreFP

// (<*>) :: Reader<env, Stateful<s, (a -> b)>> -> Reader<env, Stateful<s, a>> -> Reader<env, Stateful<s, b>>
public func <*> <Env, S, A, B>(_ rf: Reader<Env, Stateful<S, (A) -> B>>, _ ra: Reader<Env, Stateful<S, A>>) -> Reader<Env, Stateful<S, B>> {
    applyReaderStateful(rf, ra)
}

// (*>) :: Reader<env, Stateful<s, a>> -> Reader<env, Stateful<s, b>> -> Reader<env, Stateful<s, b>>
public func *> <Env, S, A, B>(_ lhs: Reader<Env, Stateful<S, A>>, _ rhs: Reader<Env, Stateful<S, B>>) -> Reader<Env, Stateful<S, B>> {
    seqRightReaderStateful(lhs, rhs)
}

// (<*) :: Reader<env, Stateful<s, a>> -> Reader<env, Stateful<s, b>> -> Reader<env, Stateful<s, a>>
public func <* <Env, S, A, B>(_ lhs: Reader<Env, Stateful<S, A>>, _ rhs: Reader<Env, Stateful<S, B>>) -> Reader<Env, Stateful<S, A>> {
    seqLeftReaderStateful(lhs, rhs)
}
