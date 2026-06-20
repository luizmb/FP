// SPDX-License-Identifier: Apache-2.0
import Foundation

// ReaderTStateful: outer = Reader, inner = Stateful
// Type: Reader<Env, Stateful<S, A>>

public extension Reader {
    /// Declaration.
    func mapT<S, A, B>(_ fn: @escaping @Sendable (A) -> B) -> Reader<Environment, Stateful<S, B>>
    where Output == Stateful<S, A> {
        mapReader { stateful in stateful.map(fn) }
    }

    /// The `property` property.
    static func fmapT<S, A, B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Reader<Environment, Stateful<S, A>>) -> Reader<Environment, Stateful<S, B>>
    where Output == Stateful<S, A> {
        { $0.mapT(fn) }
    }
}
