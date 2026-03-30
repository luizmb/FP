import CoreFPOperators
import DataStructure

// ReaderTStateful: outer = Reader, inner = Stateful
// Type: Reader<Env, Stateful<S, A>>

// (>>-) :: Reader<env, Stateful<s, a>> -> (a -> Stateful<s, b>) -> Reader<env, Stateful<s, b>>
public func >>- <Env, S, A, B>(
    _ reader: Reader<Env, Stateful<S, A>>,
    _ fn: @escaping (A) -> Stateful<S, B>
) -> Reader<Env, Stateful<S, B>> {
    reader.flatMapT(fn)
}

// (-<<) :: (a -> Stateful<s, b>) -> Reader<env, Stateful<s, a>> -> Reader<env, Stateful<s, b>>
public func -<< <Env, S, A, B>(
    _ fn: @escaping (A) -> Stateful<S, B>,
    _ reader: Reader<Env, Stateful<S, A>>
) -> Reader<Env, Stateful<S, B>> {
    reader.flatMapT(fn)
}

// (>=>) :: (a -> Reader<env, Stateful<s, b>>) -> (b -> Stateful<s, c>) -> a -> Reader<env, Stateful<s, c>>
public func >=> <Env, S, A, B, C>(
    _ fn1: @escaping (A) -> Reader<Env, Stateful<S, B>>,
    _ fn2: @escaping (B) -> Stateful<S, C>
) -> (A) -> Reader<Env, Stateful<S, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
