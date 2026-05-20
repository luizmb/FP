import CoreFP
import Foundation

public extension Reader {
    // ReaderT + Result
    func mapT<A, B, E: Error>(_ fn: @escaping @Sendable (A) -> B) -> Reader<Environment, Result<B, E>>
    where Output == Result<A, E>, A: Sendable {
        mapReader(Result<A, E>.fmap(fn))
    }

    static func fmap<A, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Reader<Environment, Result<A, E>>) -> Reader<Environment, Result<B, E>>
    where A: Sendable, Output == Result<A, E> {
        { $0.mapT(fn) }
    }

    /// replaceOutputT :: Reader<e, Result<a, err>> -> b -> Reader<e, Result<b, err>>
    func replaceOutputT<A, B, E: Error>(_ value: B) -> Reader<Environment, Result<B, E>> where Output == Result<A, E>, B: Sendable {
        mapReader { $0.map(const(value)) }
    }
}
