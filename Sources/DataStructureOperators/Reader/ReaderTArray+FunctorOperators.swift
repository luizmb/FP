import DataStructure
import Foundation
import CoreFP
import CoreFPOperators

// ReaderT + Array

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A, B, Env>(_ transform: @escaping (A) -> B, _ reader: Reader<Env, [A]>)
-> Reader<Env, [B]> {
    reader.mapT(transform)
}

// ($>) :: f a -> b -> f b
public func £> <A, B, Env>(_ reader: Reader<Env, [A]>, _ value: B) -> Reader<Env, [B]> {
    reader.mapT(const(value))
}

// (<$) :: a -> f b -> f a
public func <£ <A, B, Env>(_ value: A, _ reader: Reader<Env, [B]>) -> Reader<Env, [A]> {
    reader £> value
}
