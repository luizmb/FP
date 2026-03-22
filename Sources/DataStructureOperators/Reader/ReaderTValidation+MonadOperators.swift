import DataStructure
import CoreFPOperators
import CoreFP

// (>>-) :: Reader<env, Validation<e, a>> -> (a -> Reader<env, Validation<e, b>>) -> Reader<env, Validation<e, b>>
public func >>- <Env, E: Semigroup, A, B>(
    _ reader: Reader<Env, Validation<E, A>>,
    _ fn: @escaping (A) -> Reader<Env, Validation<E, B>>
) -> Reader<Env, Validation<E, B>> {
    reader.flatMapT(fn)
}

// (-<<) :: (a -> Reader<env, Validation<e, b>>) -> Reader<env, Validation<e, a>> -> Reader<env, Validation<e, b>>
public func -<< <Env, E: Semigroup, A, B>(
    _ fn: @escaping (A) -> Reader<Env, Validation<E, B>>,
    _ reader: Reader<Env, Validation<E, A>>
) -> Reader<Env, Validation<E, B>> {
    reader.flatMapT(fn)
}

// (>=>) :: (a -> Reader<env, Validation<e,b>>) -> (b -> Reader<env, Validation<e,c>>) -> a -> Reader<env, Validation<e,c>>
public func >=> <Env, E: Semigroup, A, B, C>(
    _ fn1: @escaping (A) -> Reader<Env, Validation<E, B>>,
    _ fn2: @escaping (B) -> Reader<Env, Validation<E, C>>
) -> (A) -> Reader<Env, Validation<E, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
