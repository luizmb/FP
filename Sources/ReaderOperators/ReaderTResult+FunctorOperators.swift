import Foundation
import FP
import Reader
import Operators

// ReaderT + Result

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A, B, E: Error, Env>(_ transform: @escaping (A) -> B, _ reader: Reader<Env, Result<A, E>>)
-> Reader<Env, Result<B, E>>
where A: Sendable, B: Sendable {
    reader.mapT(transform)
}

// ($>) :: f a -> b -> f b
public func £> <A1, A, B, Env>(_ reader: Reader<Env, Result<A, B>>, _ value: A1) -> Reader<Env, Result<A1, B>> {
    reader.replaceOutputT(value)
}

// (<$) :: a -> f b -> f a
public func <£ <A1, A, B, Env>(_ value: A1, _ reader: Reader<Env, Result<A, B>>) -> Reader<Env, Result<A1, B>> {
    reader £> value
}
