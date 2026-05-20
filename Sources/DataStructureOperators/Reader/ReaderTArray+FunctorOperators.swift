import CoreFP
import CoreFPOperators
import DataStructure
import Foundation

// ReaderT + Array

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£^> <A: Sendable, B: Sendable, Env: Sendable>(_ transform: @escaping @Sendable (A) -> B, _ reader: Reader<Env, [A]>)
-> Reader<Env, [B]> {
    reader.mapT(transform)
}

// ($>) :: f a -> b -> f b
public func £> <A: Sendable, B: Sendable, Env: Sendable>(_ reader: Reader<Env, [A]>, _ value: B) -> Reader<Env, [B]> {
    reader.mapT(const(value))
}

// (<$) :: a -> f b -> f a
public func <£ <A: Sendable, B: Sendable, Env: Sendable>(_ value: A, _ reader: Reader<Env, [B]>) -> Reader<Env, [A]> {
    reader £> value
}

// (<&^>) :: f (g a) -> (a -> b) -> f (g b)
public func <&^> <A: Sendable, B: Sendable, Env: Sendable>(_ reader: Reader<Env, [A]>, _ transform: @escaping @Sendable (A) -> B) -> Reader<Env, [B]> {
    transform <£^> reader
}
