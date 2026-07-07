// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// ReaderTWriter: outer = Reader, inner = Writer
// Type: Reader<Env, Writer<W, A>>
//
// flatMapT works: Reader's flatMap composes functions, and Writer's flatMap
// accumulates the log eagerly once the environment is applied.

public extension Reader {
    /// flatMapT :: Reader<env, Writer<w, a>> -> (a -> Writer<w, b>) -> Reader<env, Writer<w, b>>
    func flatMapT<W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> Writer<W, B>) -> Reader<Environment, Writer<W, B>>
    where Output == Writer<W, A> {
        mapReader { writer in writer.flatMap(fn) }
    }

    /// The `property` property.
    static func bindT<W: Monoid, A, B>(
        _ fn: @escaping @Sendable (A) -> Writer<W, B>
    ) -> (Reader<Environment, Writer<W, A>>) -> Reader<Environment, Writer<W, B>>
    where Output == Writer<W, A> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `ReaderT + Writer` (left-to-right)
/// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func kleisliT<Env, W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, Writer<W, B>>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, C>
) -> (A) -> Reader<Env, Writer<W, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
