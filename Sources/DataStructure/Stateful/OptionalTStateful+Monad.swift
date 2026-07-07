// SPDX-License-Identifier: Apache-2.0
import Foundation

// OptionalTStateful: outer = Optional, inner = Stateful
// Type: Stateful<S, A>? = Optional<Stateful<S, A>>
//
// Note: unlike OptionalTResult, the inner type is a function (inout S) -> A.
// We cannot inspect its output without a concrete state, so flatMapT sequences
// computations structurally: nil propagates; some(stateful) composes via flatMap.

public extension Optional {
    /// flatMapT :: Stateful<s, a>? -> (a -> Stateful<s, b>) -> Stateful<s, b>?
    /// nil             → nil
    /// some(stateful)  → some(stateful.flatMap(fn))
    func flatMapT<S, A, B>(_ fn: @escaping @Sendable (A) -> Stateful<S, B>) -> Stateful<S, B>?
    where Wrapped == Stateful<S, A> {
        map { stateful in stateful.flatMap(fn) }
    }

    /// The `property` property.
    static func bindT<S, A, B>(_ fn: @escaping @Sendable (A) -> Stateful<S, B>) -> @Sendable (Stateful<S, A>?) -> Stateful<S, B>? {
        { opt in opt.flatMapT(fn) }
    }
}

/// Kleisli composition for `OptionalT + Stateful` (left-to-right)
/// (>=>) :: (a -> Stateful<s, b>?) -> (b -> Stateful<s, c>) -> a -> Stateful<s, c>?
public func kleisliT<S, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Stateful<S, B>?,
    _ fn2: @escaping @Sendable (B) -> Stateful<S, C>
) -> (A) -> Stateful<S, C>? {
    { a in fn1(a).flatMapT(fn2) }
}
