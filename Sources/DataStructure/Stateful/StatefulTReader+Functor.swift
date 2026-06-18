// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Stateful {
    /// StatefulT + Reader — Stateful<S, Reader<Env, A>>

    func mapT<Env, Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Stateful<S, Reader<Env, B>>
    where A == Reader<Env, Inner> {
        mapStateful(Reader<Env, Inner>.fmap(fn))
    }

    /// The `property` property.
    static func fmapT<Env, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Stateful<S, Reader<Env, Inner>>) -> Stateful<S, Reader<Env, B>>
    where A == Reader<Env, Inner> {
        { $0.mapT(fn) }
    }
}
