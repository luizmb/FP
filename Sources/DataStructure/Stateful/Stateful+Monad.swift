// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Stateful {
    /// Sequences two stateful computations, threading the (possibly mutated) state from `self` into `fn`'s result.
    /// (>>=) :: Stateful s a -> (a -> Stateful s b) -> Stateful s b
    /// - Parameter fn: Produces the next `Stateful` computation from the value produced by `self`.
    /// - Returns: A `Stateful` that runs `self`, then the computation `fn` produces, threading state through both.
    func flatMap<B>(_ fn: @escaping @Sendable (A) -> Stateful<S, B>) -> Stateful<S, B> {
        Stateful<S, B> { s in
            let a = self.run(&s)
            return fn(a).run(&s)
        }
    }

    /// Curried, point-free form of ``flatMap(_:)``.
    /// (>>=) :: Stateful s a -> (a -> Stateful s b) -> Stateful s b
    static func bind<B>(
        _ fn: @escaping @Sendable (A) -> Stateful<S, B>
    ) -> (Stateful<S, A>) -> Stateful<S, B> {
        { $0.flatMap(fn) }
    }

    /// Kleisli composition (left-to-right) for `Stateful`-producing functions.
    /// (>=>) :: (o0 -> Stateful s a) -> (a -> Stateful s b) -> o0 -> Stateful s b
    static func kleisli<O0, B>(
        _ fn1: @escaping @Sendable (O0) -> Stateful<S, A>,
        _ fn2: @escaping @Sendable (A) -> Stateful<S, B>
    ) -> (O0) -> Stateful<S, B> {
        { o0 in fn1(o0).flatMap(fn2) }
    }

    /// Kleisli composition (right-to-left) for `Stateful`-producing functions.
    /// (<=<) :: (a -> Stateful s b) -> (o0 -> Stateful s a) -> o0 -> Stateful s b
    static func kleisliBack<O0, B>(
        _ fn2: @escaping @Sendable (A) -> Stateful<S, B>,
        _ fn1: @escaping @Sendable (O0) -> Stateful<S, A>
    ) -> (O0) -> Stateful<S, B> {
        { o0 in fn1(o0).flatMap(fn2) }
    }

    /// Flattens a nested `Stateful`, threading the state through the outer then the inner computation.
    /// join :: Stateful s (Stateful s a) -> Stateful s a
    static func join<O>(
        _ nested: Stateful<S, Stateful<S, O>>
    ) -> Stateful<S, O> where A == Stateful<S, O> {
        nested.flatMap(CoreFP.id)
    }

    /// Discards the produced value, keeping only the state transition.
    /// void :: Stateful s a -> Stateful s ()
    func void() -> Stateful<S, Void> {
        map(ignore)
    }
}
