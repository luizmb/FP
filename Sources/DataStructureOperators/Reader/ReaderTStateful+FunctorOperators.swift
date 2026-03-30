import CoreFPOperators
import DataStructure

// ReaderTStateful: outer = Reader, inner = Stateful
// Type: Reader<Env, Stateful<S, A>>

// (<£^>) :: (a -> b) -> Reader<env, Stateful<s, a>> -> Reader<env, Stateful<s, b>>
public func <£^> <Env, S, A, B>(_ fn: @escaping (A) -> B, _ reader: Reader<Env, Stateful<S, A>>) -> Reader<Env, Stateful<S, B>> {
    reader.mapT(fn)
}

// (<&^>) :: Reader<env, Stateful<s, a>> -> (a -> b) -> Reader<env, Stateful<s, b>>
public func <&^> <Env, S, A, B>(_ reader: Reader<Env, Stateful<S, A>>, _ fn: @escaping (A) -> B) -> Reader<Env, Stateful<S, B>> {
    reader.mapT(fn)
}
