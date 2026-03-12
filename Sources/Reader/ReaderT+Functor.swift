import Foundation
import FP

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

    // ReaderT + Reader (nested)
    func mapT<A, B, Env2>(_ fn: @escaping (A) -> B) -> Reader<Environment, Reader<Env2, B>>
    where Output == Reader<Env2, A> {
        mapReader { innerReader in
            innerReader.fmap(fn)
        }
    }

    static func fmap<A, B, Env2>(
        _ fn: @escaping (A) -> B
    ) -> (Reader<Environment, Reader<Env2, A>>) -> Reader<Environment, Reader<Env2, B>>
    where Output == Reader<Env2, A> {
        { $0.mapT(fn) }
    }

    // ReaderT + Array
    func mapT<A, B>(_ fn: @escaping (A) -> B) -> Reader<Environment, [B]>
    where Output == [A] {
        mapReader { array in
            array.map(fn)
        }
    }

    static func fmap<A, B>(
        _ fn: @escaping (A) -> B
    ) -> (Reader<Environment, [A]>) -> Reader<Environment, [B]>
    where Output == [A] {
        { $0.mapT(fn) }
    }
}
