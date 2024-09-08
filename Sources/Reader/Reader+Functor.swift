import Foundation
import FP


public extension Reader {
    func contramapEnvironment<GlobalEnvironment>(
        _ fn: @escaping (GlobalEnvironment) -> Environment
    ) -> Reader<GlobalEnvironment, Output> {
        .init(compose(fn, runReader))
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
}
