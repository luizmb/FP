// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Reader {
    /// Functor map - transforms the output value
    /// fmap :: (a -> b) -> f a -> f b
    func map<O1>(_ fn: @escaping @Sendable (Output) -> O1) -> Reader<Environment, O1> {
        mapReader(fn)
    }

    /// Curried fmap for functional composition
    static func fmap<O1>(
        _ fn: @escaping @Sendable (Output) -> O1
    ) -> @Sendable (Reader<Environment, Output>) -> Reader<Environment, O1> {
        { reader in
            reader.map(fn)
        }
    }

    /// Widens the environment a `Reader` depends on — the `Contravariant.contramap` operation.
    /// Lets a `Reader<LocalEnv, Output>` be used wherever a `Reader<GlobalEnv, Output>` is expected,
    /// by extracting the local environment out of the global one first.
    /// contramap :: (globalEnv -> env) -> Reader env a -> Reader globalEnv a
    /// - Parameter fn: Extracts the local `Environment` from a larger `GlobalEnvironment`.
    /// - Returns: A `Reader` that runs against `GlobalEnvironment` instead of `Environment`.
    func contramapEnvironment<GlobalEnvironment>(
        _ fn: @escaping @Sendable (GlobalEnvironment) -> Environment
    ) -> Reader<GlobalEnvironment, Output> {
        .init { @Sendable env in self.runReader(fn(env)) }
    }

    /// Curried, point-free form of ``contramapEnvironment(_:)``.
    /// contramap :: (globalEnv -> env) -> Reader env a -> Reader globalEnv a
    static func contramapEnvironment<GlobalEnvironment>(
        _ fn: @escaping @Sendable (GlobalEnvironment) -> Environment
    ) -> (Reader<Environment, Output>) -> Reader<GlobalEnvironment, Output> {
        { $0.contramapEnvironment(fn) }
    }

    /// Transforms the output value — same as ``map(_:)``, named after the classic Haskell Reader API.
    /// fmap :: (a -> b) -> Reader env a -> Reader env b
    func mapReader<O1>(
        _ fn: @escaping @Sendable (Output) -> O1
    ) -> Reader<Environment, O1> {
        .init { @Sendable env in fn(self.runReader(env)) }
    }

    /// Maps both the environment (contravariantly) and the output (covariantly) at once —
    /// the `Profunctor.dimap` operation.
    /// dimap :: (globalEnv -> env) -> (a -> b) -> Reader env a -> Reader globalEnv b
    /// - Parameters:
    ///   - contramapEnvironment: Extracts the local `Environment` from a larger `GlobalEnvironment`.
    ///   - mapReader: Transforms the output value.
    /// - Returns: A `Reader` from `GlobalEnvironment` to the transformed output type.
    func dimap<GlobalEnvironment, O1>(
        _ contramapEnvironment: @escaping @Sendable (GlobalEnvironment) -> Environment,
        _ mapReader: @escaping @Sendable (Output) -> O1
    ) -> Reader<GlobalEnvironment, O1> {
        .init { @Sendable env in mapReader(self.runReader(contramapEnvironment(env))) }
    }

    /// Curried, point-free form of ``dimap(_:_:)``.
    /// dimap :: (globalEnv -> env) -> (a -> b) -> Reader env a -> Reader globalEnv b
    static func dimap<GlobalEnvironment, O1>(
        _ contramapEnv: @escaping @Sendable (GlobalEnvironment) -> Environment,
        _ mapOut: @escaping @Sendable (Output) -> O1
    ) -> (Reader<Environment, Output>) -> Reader<GlobalEnvironment, O1> {
        { $0.dimap(contramapEnv, mapOut) }
    }
}
