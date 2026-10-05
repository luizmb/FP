// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// StatefulT + Either — free functions for Stateful<S, Either<L, A>>

/// apply for Stateful<S, Either>
/// Equals `ap`: `sf >>= \f -> fmap f sa`. Sequential and short-circuiting like `flatMapT`:
/// when the function side fails, the right-hand state effect never happens.
func applyStatefulEither<S, L: Sendable, A: Sendable, B: Sendable>(
    _ sf: Stateful<S, Either<L, @Sendable (A) -> B>>,
    _ sa: Stateful<S, Either<L, A>>
) -> Stateful<S, Either<L, B>> {
    sf.flatMapT { f in sa.mapT(f) }
}

/// liftA2 for Stateful<S, Either>
/// Equals `a >>= \x -> fmap (f x) b`. When `a` fails, `b`'s state effect never happens.
func liftA2StatefulEither<S, L: Sendable, A: Sendable, B: Sendable, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (Stateful<S, Either<L, A>>, Stateful<S, Either<L, B>>) -> Stateful<S, Either<L, C>> {
    { sa, sb in sa.flatMapT { a in sb.mapT { b in fn(a, b) } } }
}

/// seqRight for Stateful<S, Either>
/// Equals `a >>= \_ -> b`. When `lhs` fails, `rhs`'s state effect never happens.
func seqRightStatefulEither<S, L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, Either<L, A>>,
    _ rhs: Stateful<S, Either<L, B>>
) -> Stateful<S, Either<L, B>> {
    lhs.flatMapT(const(rhs))
}

/// seqLeft for Stateful<S, Either>
/// Equals `a >>= \x -> fmap (const x) b`. When `lhs` fails, `rhs`'s state effect never happens.
func seqLeftStatefulEither<S, L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, Either<L, A>>,
    _ rhs: Stateful<S, Either<L, B>>
) -> Stateful<S, Either<L, A>> {
    lhs.flatMapT { a in rhs.mapT(const(a)) }
}
