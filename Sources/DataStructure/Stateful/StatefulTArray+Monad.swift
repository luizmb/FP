// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Stateful {
    /// StatefulT + Array — Stateful<S, [A]>

    func flatMapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, [B]>
    ) -> Stateful<S, [B]> where A == [Inner] {
        Stateful<S, [B]> { s in
            self.run(&s).flatMap { a in fn(a).run(&s) }
        }
    }

    /// The `property` property.
    static func bindT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, [B]>
    ) -> (Stateful<S, [Inner]>) -> Stateful<S, [B]> where A == [Inner] {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `StatefulT + Array` (left-to-right)
/// (>=>) :: (a -> Stateful<s, [b]>) -> (b -> Stateful<s, [c]>) -> a -> Stateful<s, [c]>
public func kleisliT<S, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Stateful<S, [B]>,
    _ fn2: @escaping @Sendable (B) -> Stateful<S, [C]>
) -> (A) -> Stateful<S, [C]> {
    { a in fn1(a).flatMapT(fn2) }
}
