// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// ReaderTWriter: outer = Reader, inner = Writer
// Type: Reader<Env, Writer<W, A>>  (Haskell: ReaderT r (Writer w))
//
// Bind runs `self` with the environment, feeds the value to `fn`, runs the resulting
// Reader with the same environment and appends the logs left to right.

public extension Reader {
    /// flatMapT :: Reader<env, Writer<w, a>> -> (a -> Reader<env, Writer<w, b>>) -> Reader<env, Writer<w, b>>
    func flatMapT<W: Monoid, A, B>(
        _ fn: @escaping @Sendable (A) -> Reader<Environment, Writer<W, B>>
    ) -> Reader<Environment, Writer<W, B>>
    where Output == Writer<W, A> {
        Reader<Environment, Writer<W, B>> { env in
            self(env).flatMap { a in fn(a)(env) }
        }
    }

    /// Curried `flatMapT`: lifts a full-stack continuation into a transformation of `ReaderTWriter` values.
    static func bindT<W: Monoid, A, B>(
        _ fn: @escaping @Sendable (A) -> Reader<Environment, Writer<W, B>>
    ) -> @Sendable (Reader<Environment, Writer<W, A>>) -> Reader<Environment, Writer<W, B>>
    where Output == Writer<W, A> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `ReaderT + Writer` (left-to-right)
/// (>=>) :: (a -> Reader<env, Writer<w, b>>) -> (b -> Reader<env, Writer<w, c>>) -> a -> Reader<env, Writer<w, c>>
public func kleisliT<Env, W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, Writer<W, B>>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, Writer<W, C>>
) -> @Sendable (A) -> Reader<Env, Writer<W, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
