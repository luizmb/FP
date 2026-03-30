import CoreFP
import DataStructure
import Foundation
import CoreFPOperators

// ReaderT + Reader (nested)

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£^> <A, B, Env1, Env2>(_ transform: @escaping (A) -> B, _ reader: Reader<Env1, Reader<Env2, A>>)
-> Reader<Env1, Reader<Env2, B>> {
    reader.mapT(transform)
}

// ($>) :: f a -> b -> f b
public func £> <A, B, Env1, Env2>(_ reader: Reader<Env1, Reader<Env2, A>>, _ value: B) -> Reader<Env1, Reader<Env2, B>> {
    reader.mapT(const(value))
}

// (<$) :: a -> f b -> f a
public func <£ <A, B, Env1, Env2>(_ value: A, _ reader: Reader<Env1, Reader<Env2, B>>) -> Reader<Env1, Reader<Env2, A>> {
    reader £> value
}

// (<&^>) :: f (g a) -> (a -> b) -> f (g b)
public func <&^> <A, B, Env1, Env2>(
    _ reader: Reader<Env1, Reader<Env2, A>>,
    _ transform: @escaping (A) -> B
) -> Reader<Env1, Reader<Env2, B>> {
    transform <£^> reader
}
