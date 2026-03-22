import Foundation
import CoreFP

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

    /// replaceOutputT :: Reader<e, a?> -> b -> Reader<e, b?>
    func replaceOutputT<A, B>(_ value: B) -> Reader<Environment, B?> where Output == A? {
        mapReader { $0.map(const(value)) }
    }
}
