import Foundation
import Core

public extension Reader {
    // ReaderT + Either
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
}
