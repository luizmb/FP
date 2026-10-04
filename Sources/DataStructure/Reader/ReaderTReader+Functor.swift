// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Reader {
    /// ReaderT + Reader (nested)
    func mapT<A, B, Env2>(_ fn: @escaping @Sendable (A) -> B) -> Reader<Environment, Reader<Env2, B>>
    where Output == Reader<Env2, A> {
        mapReader { innerReader in innerReader.map(fn) }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<A, B, Env2>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Reader<Environment, Reader<Env2, A>>) -> Reader<Environment, Reader<Env2, B>>
    where Output == Reader<Env2, A> {
        { $0.mapT(fn) }
    }
}
