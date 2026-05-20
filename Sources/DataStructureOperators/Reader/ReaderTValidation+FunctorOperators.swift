import CoreFP
import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> Reader<env, Validation<e, a>> -> Reader<env, Validation<e, b>>
public func <£^> <Env, E: Semigroup, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ reader: Reader<Env, Validation<E, A>>
) -> Reader<Env, Validation<E, B>> {
    reader.mapReader { $0.mapSuccess(fn) }
}

// (<&^>) :: Reader<env, Validation<e, a>> -> (a -> b) -> Reader<env, Validation<e, b>>
public func <&^> <Env, E: Semigroup, A, B>(
    _ reader: Reader<Env, Validation<E, A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Reader<Env, Validation<E, B>> {
    reader.mapReader { $0.mapSuccess(fn) }
}
