import DataStructure
import Foundation
import Core
import CoreOperators

// ReaderT + Either

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A, B, L, Env>(_ transform: @escaping (A) -> B, _ reader: Reader<Env, Either<L, A>>)
-> Reader<Env, Either<L, B>>
where A: Sendable, B: Sendable, L: Sendable {
    reader.mapT(transform)
}

// ($>) :: Either a b -> a0 -> Either a a0
public func £> <B1, A, B, Env>(_ reader: Reader<Env, Either<A, B>>, _ value: B1) -> Reader<Env, Either<A, B1>> {
    Reader { env in
        let either: Either<A, B> = reader(env)
        let result: Either<A, B1> = either £> value
        return result
    }
}

// (<$) :: a0 -> Either a b -> Either a a0
public func <£ <B1, A, B, Env>(_ value: B1, _ reader: Reader<Env, Either<A, B>>) -> Reader<Env, Either<A, B1>> {
    reader £> value
}
