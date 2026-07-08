// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Stateful {
    /// Transforms the produced value, leaving the state-transition untouched — named after the classic Haskell State API.
    /// fmap :: (a -> b) -> Stateful s a -> Stateful s b
    func mapStateful<B>(_ fn: @escaping @Sendable (A) -> B) -> Stateful<S, B> {
        Stateful<S, B> { s in fn(self.run(&s)) }
    }

    /// Transforms the produced value, leaving the state-transition untouched (the `Functor.map` for `Stateful`).
    /// fmap :: (a -> b) -> Stateful s a -> Stateful s b
    func map<B>(_ fn: @escaping @Sendable (A) -> B) -> Stateful<S, B> {
        mapStateful(fn)
    }

    /// Curried, point-free form of ``map(_:)``.
    /// fmap :: (a -> b) -> Stateful s a -> Stateful s b
    static func fmap<B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Stateful<S, A>) -> Stateful<S, B> {
        { $0.mapStateful(fn) }
    }
}
