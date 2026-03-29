import CoreFP
import Foundation

public extension Reader {
    // ReaderT + Reader (nested)
    func mapT<A, B, Env2>(_ fn: @escaping (A) -> B) -> Reader<Environment, Reader<Env2, B>>
    where Output == Reader<Env2, A> {
        mapReader { innerReader in innerReader.fmap(fn) }
    }

    static func fmap<A, B, Env2>(
        _ fn: @escaping (A) -> B
    ) -> (Reader<Environment, Reader<Env2, A>>) -> Reader<Environment, Reader<Env2, B>>
    where Output == Reader<Env2, A> {
        { $0.mapT(fn) }
    }
}
