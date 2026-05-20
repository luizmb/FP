import CoreFP
import Foundation

public extension Reader {
    /// Monadic bind operation for Reader
    /// (>>=) :: m a -> (a -> m b) -> m b
    func flatMap<O1>(_ fn: @escaping @Sendable (Output) -> Reader<Environment, O1>) -> Reader<Environment, O1> {
        Reader<Environment, O1> { env in
            fn(self.runReader(env)).runReader(env)
        }
    }

    /// Curried version of flatMap for functional composition
    /// (>>=) :: m a -> (a -> m b) -> m b
    static func bind<O1>(
        _ fn: @escaping @Sendable (Output) -> Reader<Environment, O1>
    ) -> (Reader<Environment, Output>) -> Reader<Environment, O1> {
        { reader in
            reader.flatMap(fn)
        }
    }

    /// Kleisli composition (left-to-right)
    /// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
    static func kleisli<O0, O1>(
        _ fn1: @escaping @Sendable (O0) -> Reader<Environment, Output>,
        _ fn2: @escaping @Sendable (Output) -> Reader<Environment, O1>
    ) -> (O0) -> Reader<Environment, O1> {
        { o0 in
            fn1(o0).flatMap(fn2)
        }
    }

    /// Kleisli composition (right-to-left)
    /// (<=<) :: (b -> m c) -> (a -> m b) -> a -> m c
    static func kleisliBack<O0, O1>(
        _ fn2: @escaping @Sendable (Output) -> Reader<Environment, O1>,
        _ fn1: @escaping @Sendable (O0) -> Reader<Environment, Output>
    ) -> (O0) -> Reader<Environment, O1> {
        { o0 in
            fn1(o0).flatMap(fn2)
        }
    }

    /// Monadic join - flattens nested Readers
    /// join :: m (m a) -> m a
    static func join<O>(
        _ nested: Reader<Environment, Reader<Environment, O>>
    ) -> Reader<Environment, O> where Output == Reader<Environment, O> {
        Reader<Environment, O> { env in
            nested.runReader(env).runReader(env)
        }
    }

    /// Asks for the environment
    /// ask :: m env
    static var ask: Reader<Environment, Environment> {
        Reader<Environment, Environment>(id)
    }

    /// Retrieves a function of the environment
    /// asks :: (env -> a) -> m a
    static func asks<O>(_ fn: @escaping @Sendable (Environment) -> O) -> Reader<Environment, O> {
        Reader<Environment, O>(fn)
    }

    /// Discards the output, keeping only the structure
    /// void :: m a -> m ()
    func void() -> Reader<Environment, Void> {
        mapReader(ignore)
    }

    /// Executes a computation in a modified environment
    /// local :: (env -> env) -> m a -> m a
    func local(_ fn: @escaping @Sendable (Environment) -> Environment) -> Reader<Environment, Output> {
        Reader { env in
            self.runReader(fn(env))
        }
    }
}
