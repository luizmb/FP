// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Stateful {
    /// StatefulT + Result — Stateful<S, Result<A, E>>

    func flatMapT<Inner, B, E: Error>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, Result<B, E>>
    ) -> Stateful<S, Result<B, E>> where A == Result<Inner, E> {
        Stateful<S, Result<B, E>> { s in
            self.run(&s).flatMap { a in fn(a).run(&s) }
        }
    }

    /// The `property` property.
    static func bindT<Inner, B, E: Error>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, Result<B, E>>
    ) -> (Stateful<S, Result<Inner, E>>) -> Stateful<S, Result<B, E>>
    where A == Result<Inner, E> {
        { $0.flatMapT(fn) }
    }
}
