// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Stateful {
    /// Declaration.
    func mapStateful<B>(_ fn: @escaping @Sendable (A) -> B) -> Stateful<S, B> {
        Stateful<S, B> { s in fn(self.run(&s)) }
    }

    /// Declaration.
    func map<B>(_ fn: @escaping @Sendable (A) -> B) -> Stateful<S, B> {
        mapStateful(fn)
    }

    /// The `property` property.
    static func fmap<B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Stateful<S, A>) -> Stateful<S, B> {
        { $0.mapStateful(fn) }
    }
}
