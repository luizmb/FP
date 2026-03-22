import DataStructure
import Foundation
import Core
import CoreOperators

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <Env, A, B>(
    _ transform: @escaping (A) -> B,
    _ reader: Reader<Env, A>
) -> Reader<Env, B> {
    reader.fmap(transform)
}

// ($>) :: f a -> b -> f b
public func £> <Env, A, B>(
    _ reader: Reader<Env, A>,
    _ value: B
) -> Reader<Env, B> {
    reader.fmap(const(value))
}

// (<$) :: b -> f a -> f b
public func <£ <Env, A, B>(
    _ value: B,
    _ reader: Reader<Env, A>
) -> Reader<Env, B> {
    reader £> value
}
