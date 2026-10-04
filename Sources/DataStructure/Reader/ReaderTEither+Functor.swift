// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Reader {
    /// ReaderT + Either
    func mapT<A, B, L>(_ fn: @escaping @Sendable (A) -> B) -> Reader<Environment, Either<L, B>>
    where Output == Either<L, A>, A: Sendable, L: Sendable {
        mapReader(Either<L, A>.fmap(fn))
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<A, B, L>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Reader<Environment, Either<L, A>>) -> Reader<Environment, Either<L, B>>
    where A: Sendable, L: Sendable, Output == Either<L, A> {
        { $0.mapT(fn) }
    }
}
