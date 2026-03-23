import Foundation
import CoreFP

public extension Reader {
    /// Functor map - transforms the output value
    /// fmap :: (a -> b) -> f a -> f b
    func fmap<O1>(_ fn: @escaping (Output) -> O1) -> Reader<Environment, O1> {
        mapReader(fn)
    }

    /// Curried fmap for functional composition
    static func fmap<O1>(
        _ fn: @escaping (Output) -> O1
    ) -> (Reader<Environment, Output>) -> Reader<Environment, O1> {
        { reader in
            reader.fmap(fn)
        }
    }

    func contramapEnvironment<GlobalEnvironment>(
        _ fn: @escaping (GlobalEnvironment) -> Environment
    ) -> Reader<GlobalEnvironment, Output> {
        .init(compose(fn, runReader))
    }

    static func contramapEnvironment<GlobalEnvironment>(
        _ fn: @escaping (GlobalEnvironment) -> Environment
    ) -> (Reader<Environment, Output>) -> Reader<GlobalEnvironment, Output> {
        { $0.contramapEnvironment(fn) }
    }

    func mapReader<O1>(
        _ fn: @escaping (Output) -> O1
    ) -> Reader<Environment, O1> {
        .init(compose(runReader, fn))
    }

    func dimap<GlobalEnvironment, O1>(
        _ contramapEnvironment: @escaping (GlobalEnvironment) -> Environment,
        _ mapReader: @escaping (Output) -> O1
    ) -> Reader<GlobalEnvironment, O1> {
        .init(compose3(contramapEnvironment, runReader, mapReader))
    }

    static func dimap<GlobalEnvironment, O1>(
        _ contramapEnv: @escaping (GlobalEnvironment) -> Environment,
        _ mapOut: @escaping (Output) -> O1
    ) -> (Reader<Environment, Output>) -> Reader<GlobalEnvironment, O1> {
        { $0.dimap(contramapEnv, mapOut) }
    }
}
