import Foundation
import FP
#if canImport(Either)
import Either
#endif
#if canImport(Combine) && canImport(CombineFP)
import Combine
import CombineFP
#endif

#if canImport(Operators)
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

// ReaderT + Either

#if canImport(Either)
// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A, B, L, Env>(_ transform: @escaping (A) -> B, _ reader: Reader<Env, Either<L, A>>) 
-> Reader<Env, Either<L, B>>
where A: Sendable, B: Sendable, L: Sendable {
    reader.mapT(transform)
}

// ($>) :: Either a b -> a0 -> Either a a0
public func £> <B1, A, B, Env>(_ reader: Reader<Env, Either<A, B>>, _ value: B1) -> Reader<Env, Either<A, B1>> {
    Reader { env in
        reader(env) £> value
    }
}

// (<$) :: a0 -> Either a b -> Either a a0
public func <£ <B1, A, B, Env>(_ value: B1, _ reader: Reader<Env, Either<A, B>>) -> Reader<Env, Either<A, B1>> {
    reader £> value
}

#endif

// ReaderT + Publisher

#if canImport(Combine) && canImport(CombineFP)
// (<$>) :: Functor f => (a -> b) -> f a -> f b
@available(macOS 13.0, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£> <A, B, E: Error, Env>(_ transform: @escaping (A) -> B, _ reader: Reader<Env, any Publisher<A, E>>) 
-> Reader<Env, any Publisher<B, E>>
where A: Sendable, B: Sendable {
    reader.mapT(transform)
}

// ($>) :: Either a b -> a0 -> Either a a0
@available(macOS 13.0, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func £> <A1, A, B: Error, Env>(_ reader: Reader<Env, any Publisher<A, B>>, _ value: A1) 
-> Reader<Env, any Publisher<A1, B>> {
    Reader { env in 
        reader(env) £> value
    }
}

// (<$) :: a0 -> Either a b -> Either a a0
@available(macOS 13.0, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£ <A1, A, B: Error, Env>(_ value: A1, _ reader: Reader<Env, any Publisher<A, B>>) 
-> Reader<Env, any Publisher<A1, B>> {
    reader £> value
}
#endif

#endif

public extension Reader {
    // ReaderT + Optional
    func mapT<A, B>(_ fn: @escaping (A) -> B) -> Reader<Environment, B?> where Output == A?, A: Sendable {
        mapReader(A?.fmap(fn))
    }

    static func fmap<A, B>(
        _ fn: @escaping (A) -> B
    ) -> (Reader<Environment, A?>) -> Reader<Environment, B?> 
    where A: Sendable, Output == A? {
        { $0.mapT(fn) }
    }

    // ReaderT + Result
    func mapT<A, B, E: Error>(_ fn: @escaping (A) -> B) -> Reader<Environment, Result<B, E>> 
    where Output == Result<A, E>, A: Sendable {
        mapReader(Result<A, E>.fmap(fn))
    }

    static func fmap<A, B, E: Error>(
        _ fn: @escaping (A) -> B
    ) -> (Reader<Environment, Result<A, E>>) -> Reader<Environment, Result<B, E>> 
    where A: Sendable, Output == Result<A, E> {
        { $0.mapT(fn) }
    }

    // ReaderT + Either
    #if canImport(Either)
    func mapT<A, B, L>(_ fn: @escaping (A) -> B) -> Reader<Environment, Either<L, B>> 
    where Output == Either<L, A>, A: Sendable, L: Sendable {
        mapReader(Either<L, A>.fmap(fn))
    }

    static func fmap<A, B, L>(
        _ fn: @escaping (A) -> B
    ) -> (Reader<Environment, Either<L, A>>) -> Reader<Environment, Either<L, B>> 
    where A: Sendable, L: Sendable, Output == Either<L, A> {
        { $0.mapT(fn) }
    }
    #endif

    // ReaderT + Publisher
    #if canImport(Combine) && canImport(CombineFP)
    @available(macOS 13.0, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func mapT<A, B, E: Error>(_ fn: @escaping (A) -> B) -> Reader<Environment, any Publisher<B, E>> 
    where Output == any Publisher<A, E>, A: Sendable {
        mapReader(AnyPublisher<A, E>.fmap(fn))
    }

    @available(macOS 13.0, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    static func fmap<A, B, E: Error>(
        _ fn: @escaping (A) -> B
    ) -> (Reader<Environment, any Publisher<A, E>>) -> Reader<Environment, any Publisher<B, E>> 
    where A: Sendable, Output == any Publisher<A, E> {
        { $0.mapT(fn) }
    }
    #endif
}
