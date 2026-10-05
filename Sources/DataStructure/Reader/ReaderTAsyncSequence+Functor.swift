// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

extension Reader {
    // ReaderT + AsyncSequence
    /// Declaration.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func mapT<A, B>(_ fn: @escaping @Sendable (A) -> B) -> Reader<Environment, AsyncMapSequence<AsyncStream<A>, B>>
    where Output == AsyncStream<A> {
        mapReader { stream in
            stream.map(fn)
        }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    static func fmapT<A, B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Reader<Environment, AsyncStream<A>>) -> Reader<Environment, AsyncMapSequence<AsyncStream<A>, B>>
    where Output == AsyncStream<A> {
        { $0.mapT(fn) }
    }
}
