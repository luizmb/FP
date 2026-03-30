import CoreFPOperators
import DataStructure
import Foundation

// ReaderT + Optional

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£^> <A, B, Env>(_ transform: @escaping (A) -> B, _ reader: Reader<Env, A?>)
-> Reader<Env, B?>
where A: Sendable, B: Sendable {
    reader.mapT(transform)
}

// ($>) :: f a -> b -> f b
public func £> <A1, A, Env>(_ reader: Reader<Env, A?>, _ value: A1) -> Reader<Env, A1?> {
    reader.replaceOutputT(value)
}

// (<$) :: a -> f b -> f a
public func <£ <A1, A, Env>(_ value: A1, _ reader: Reader<Env, A?>) -> Reader<Env, A1?> {
    reader £> value
}

// (<&^>) :: f (g a) -> (a -> b) -> f (g b)
public func <&^> <A, B, Env>(_ reader: Reader<Env, A?>, _ transform: @escaping (A) -> B) -> Reader<Env, B?>
where A: Sendable, B: Sendable {
    transform <£^> reader
}
