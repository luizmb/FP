// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Reader {
    /// ReaderT + Array
    func mapT<A, B>(_ fn: @escaping @Sendable (A) -> B) -> Reader<Environment, [B]>
    where Output == [A] {
        mapReader { array in
            array.map(fn)
        }
    }

    /// The `property` property.
    static func fmap<A, B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Reader<Environment, [A]>) -> Reader<Environment, [B]>
    where Output == [A] {
        { $0.mapT(fn) }
    }
}
