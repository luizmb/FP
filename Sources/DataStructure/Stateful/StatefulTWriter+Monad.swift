// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// StatefulTWriter: outer = Stateful, inner = Writer
// Type: Stateful<S, Writer<W, A>>  (Haskell: StateT s (Writer w), up to isomorphism)
//
// Bind threads the state through `self` and then through `fn(a)`, appending the logs
// left to right.

public extension Stateful {
    /// flatMapT :: Stateful<s, Writer<w, a>> -> (a -> Stateful<s, Writer<w, b>>) -> Stateful<s, Writer<w, b>>
    func flatMapT<W: Monoid, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, Writer<W, B>>
    ) -> Stateful<S, Writer<W, B>>
    where A == Writer<W, Inner> {
        Stateful<S, Writer<W, B>> { s in
            let first = self.run(&s)
            let second = fn(first.value).run(&s)
            return Writer<W, B>(second.value, W.combine(first.log, second.log))
        }
    }

    /// Curried `flatMapT`: lifts a full-stack continuation into a transformation of `StatefulTWriter` values.
    static func bindT<W: Monoid, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, Writer<W, B>>
    ) -> @Sendable (Stateful<S, Writer<W, Inner>>) -> Stateful<S, Writer<W, B>>
    where A == Writer<W, Inner> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `StatefulT + Writer` (left-to-right)
/// (>=>) :: (a -> Stateful<s, Writer<w, b>>) -> (b -> Stateful<s, Writer<w, c>>) -> a -> Stateful<s, Writer<w, c>>
public func kleisliT<S, W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Stateful<S, Writer<W, B>>,
    _ fn2: @escaping @Sendable (B) -> Stateful<S, Writer<W, C>>
) -> @Sendable (A) -> Stateful<S, Writer<W, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
