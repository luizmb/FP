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

    /// Declaration.
    func contramapEnvironment<GlobalEnvironment>(
        _ fn: @escaping @Sendable (GlobalEnvironment) -> Environment
    ) -> Reader<GlobalEnvironment, Output> {
        .init { @Sendable env in self.runReader(fn(env)) }
    }

    /// The `property` property.
    static func contramapEnvironment<GlobalEnvironment>(
        _ fn: @escaping @Sendable (GlobalEnvironment) -> Environment
    ) -> (Reader<Environment, Output>) -> Reader<GlobalEnvironment, Output> {
        { $0.contramapEnvironment(fn) }
    }

    /// Declaration.
    func mapReader<O1>(
        _ fn: @escaping @Sendable (Output) -> O1
    ) -> Reader<Environment, O1> {
        .init { @Sendable env in fn(self.runReader(env)) }
    }

    /// Declaration.
    func dimap<GlobalEnvironment, O1>(
        _ contramapEnvironment: @escaping @Sendable (GlobalEnvironment) -> Environment,
        _ mapReader: @escaping @Sendable (Output) -> O1
    ) -> Reader<GlobalEnvironment, O1> {
        .init { @Sendable env in mapReader(self.runReader(contramapEnvironment(env))) }
    }

    /// The `property` property.
    static func dimap<GlobalEnvironment, O1>(
        _ contramapEnv: @escaping @Sendable (GlobalEnvironment) -> Environment,
        _ mapOut: @escaping @Sendable (Output) -> O1
    ) -> (Reader<Environment, Output>) -> Reader<GlobalEnvironment, O1> {
        { $0.dimap(contramapEnv, mapOut) }
    }
}
