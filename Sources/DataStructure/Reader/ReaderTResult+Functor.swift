// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Reader {
    /// ReaderT + Result
    func mapT<A, B, E: Error>(_ fn: @escaping @Sendable (A) -> B) -> Reader<Environment, Result<B, E>>
    where Output == Result<A, E>, A: Sendable {
        mapReader(Result<A, E>.fmap(fn))
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<A, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Reader<Environment, Result<A, E>>) -> Reader<Environment, Result<B, E>>
    where A: Sendable, Output == Result<A, E> {
        { $0.mapT(fn) }
    }
}
