// SPDX-License-Identifier: Apache-2.0
// ReaderTNonEmpty: outer = Reader, inner = NonEmpty
// Type: Reader<Environment, NonEmpty<A>>  (Haskell: ReaderT r NonEmpty)
//
// Bind runs `self` with the environment, runs `fn(a)` with the same environment for every
// element and concatenates the results in order (NonEmpty bind).

extension Reader {
    /// flatMapT :: Reader<env, NonEmpty<a>> -> (a -> Reader<env, NonEmpty<b>>) -> Reader<env, NonEmpty<b>>
    func flatMapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Reader<Environment, NonEmpty<B>>
    ) -> Reader<Environment, NonEmpty<B>> where Output == NonEmpty<Inner> {
        Reader<Environment, NonEmpty<B>> { env in
            self(env).flatMap { inner in fn(inner)(env) }
        }
    }

    /// Curried `flatMapT`: lifts a full-stack continuation into a transformation of `ReaderTNonEmpty` values.
    static func bindT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Reader<Environment, NonEmpty<B>>
    ) -> @Sendable (Reader<Environment, NonEmpty<Inner>>) -> Reader<Environment, NonEmpty<B>>
    where Output == NonEmpty<Inner> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `ReaderT + NonEmpty` (left-to-right)
/// (>=>) :: (a -> Reader<env, NonEmpty<b>>) -> (b -> Reader<env, NonEmpty<c>>) -> a -> Reader<env, NonEmpty<c>>
func kleisliT<Env, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, NonEmpty<B>>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, NonEmpty<C>>
) -> @Sendable (A) -> Reader<Env, NonEmpty<C>> {
    { a in fn1(a).flatMapT(fn2) }
}
