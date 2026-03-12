import Foundation
import FP
import Reader
import Operators

// ReaderT + Optional

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A, B, Env>(_ transform: @escaping (A) -> B, _ reader: Reader<Env, Optional<A>>)
-> Reader<Env, Optional<B>>
where A: Sendable, B: Sendable {
    reader.mapT(transform)
}

// ($>) :: Either a b -> a0 -> Either a a0
public func £> <A1, A, Env>(_ reader: Reader<Env, Optional<A>>, _ value: A1) -> Reader<Env, Optional<A1>> {
    Reader { env in
        reader(env) £> value
    }
}

// (<$) :: a0 -> Either a b -> Either a a0
public func <£ <A1, A, Env>(_ value: A1, _ reader: Reader<Env, Optional<A>>) -> Reader<Env, Optional<A1>> {
    reader £> value
}

// ReaderT + Result

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A, B, E: Error, Env>(_ transform: @escaping (A) -> B, _ reader: Reader<Env, Result<A, E>>)
-> Reader<Env, Result<B, E>>
where A: Sendable, B: Sendable {
    reader.mapT(transform)
}

// ($>) :: Either a b -> a0 -> Either a a0
public func £> <A1, A, B, Env>(_ reader: Reader<Env, Result<A, B>>, _ value: A1) -> Reader<Env, Result<A1, B>> {
    Reader { env in
        reader(env) £> value
    }
}

// (<$) :: a0 -> Either a b -> Either a a0
public func <£ <A1, A, B, Env>(_ value: A1, _ reader: Reader<Env, Result<A, B>>) -> Reader<Env, Result<A1, B>> {
    reader £> value
}

// ReaderT + Reader (nested)

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A, B, Env1, Env2>(_ transform: @escaping (A) -> B, _ reader: Reader<Env1, Reader<Env2, A>>)
-> Reader<Env1, Reader<Env2, B>> {
    reader.mapT(transform)
}

// ($>) :: f a -> b -> f b
public func £> <A, B, Env1, Env2>(_ reader: Reader<Env1, Reader<Env2, A>>, _ value: B) -> Reader<Env1, Reader<Env2, B>> {
    reader.mapT { _ in value }
}

// (<$) :: a -> f b -> f a
public func <£ <A, B, Env1, Env2>(_ value: A, _ reader: Reader<Env1, Reader<Env2, B>>) -> Reader<Env1, Reader<Env2, A>> {
    reader £> value
}

// ReaderT + Array

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A, B, Env>(_ transform: @escaping (A) -> B, _ reader: Reader<Env, [A]>)
-> Reader<Env, [B]> {
    reader.mapT(transform)
}

// ($>) :: f a -> b -> f b
public func £> <A, B, Env>(_ reader: Reader<Env, [A]>, _ value: B) -> Reader<Env, [B]> {
    reader.mapT { _ in value }
}

// (<$) :: a -> f b -> f a
public func <£ <A, B, Env>(_ value: A, _ reader: Reader<Env, [B]>) -> Reader<Env, [A]> {
    reader £> value
}

