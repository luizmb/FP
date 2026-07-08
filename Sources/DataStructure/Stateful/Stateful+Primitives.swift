// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Stateful {
    /// Returns the current state as the produced value, without modifying it.
    /// get :: Stateful s s
    static var get: Stateful<S, S> {
        // swiftlint:disable:next unnecessary_single_param_closure
        Stateful<S, S> { s in s } // `s` is inout — cannot use `id`, which takes (T) -> T not (inout T) -> T
    }

    /// Extracts a derived value from the current state, without modifying it.
    /// gets :: (s -> b) -> Stateful s b
    /// - Parameter f: A function computing the derived value from the current state.
    /// - Returns: A `Stateful` that reads the state and returns `f` applied to it.
    static func gets<B>(_ f: @escaping @Sendable (S) -> B) -> Stateful<S, B> {
        Stateful<S, B> { s in f(s) }
    }

    /// Replaces the state with `new`, producing no value.
    /// put :: s -> Stateful s ()
    static func put(_ new: S) -> Stateful<S, Void> where S: Sendable {
        Stateful<S, Void> { s in s = new }
    }

    /// Transforms the state with a pure function, producing no value.
    /// modify :: (s -> s) -> Stateful s ()
    static func modify(_ f: @escaping @Sendable (S) -> S) -> Stateful<S, Void> {
        Stateful<S, Void> { s in s = f(s) }
    }

    /// Transforms the state in place via an `inout` closure, producing no value.
    /// Prefer this over ``modify(_:)`` for copy-on-write types where an in-place mutation avoids a copy.
    /// modify :: (s -> s) -> Stateful s ()
    static func modifyInPlace(_ f: @escaping @Sendable (inout S) -> Void) -> Stateful<S, Void> {
        Stateful<S, Void> { s in f(&s) }
    }

    /// Lifts a value into `Stateful` without reading or modifying the state.
    /// pure :: a -> Stateful s a
    static func pure(_ value: A) -> Stateful<S, A> where A: Sendable {
        // swiftlint:disable:next closure_ignoring_args unnecessary_single_param_closure
        Stateful<S, A> { _ in value } // `_` is inout S — `const` takes (T)->A not (inout T)->A
    }
}
