// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// StatefulT + Either — free functions for Stateful<S, Either<L, A>>

/// apply for Stateful<S, Either>
/// Equals `ap`: `sf >>= \f -> fmap f sa`. Sequential and short-circuiting like `flatMapT`:
/// when the function side fails, the right-hand state effect never happens.
public func applyStatefulEither<S, L: Sendable, A: Sendable, B: Sendable>(
    _ sf: Stateful<S, Either<L, @Sendable (A) -> B>>,
    _ sa: Stateful<S, Either<L, A>>
) -> Stateful<S, Either<L, B>> {
    sf.flatMapT { f in sa.mapT(f) }
}

/// liftA2 for Stateful<S, Either>
/// Equals `a >>= \x -> fmap (f x) b`. When `a` fails, `b`'s state effect never happens.
/// Inlined (same body as `flatMapT` + `mapT`) because `A` is not required to be `Sendable`.
public func liftA2StatefulEither<S, L, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Stateful<S, Either<L, A>>, Stateful<S, Either<L, B>>) -> Stateful<S, Either<L, C>> {
    { sa, sb in
        Stateful<S, Either<L, C>> { s in
            switch sa.run(&s) {
            case let .left(l):
                .left(l)

            case let .right(a):
                switch sb.run(&s) {
                case let .left(l):
                    .left(l)

                case let .right(b):
                    .right(fn(a, b))
                }
            }
        }
    }
}

/// seqRight for Stateful<S, Either>
/// Equals `a >>= \_ -> b`. When `lhs` fails, `rhs`'s state effect never happens.
public func seqRightStatefulEither<S, L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, Either<L, A>>,
    _ rhs: Stateful<S, Either<L, B>>
) -> Stateful<S, Either<L, B>> {
    lhs.flatMapT(const(rhs))
}

/// seqLeft for Stateful<S, Either>
/// Equals `a >>= \x -> fmap (const x) b`. When `lhs` fails, `rhs`'s state effect never happens.
public func seqLeftStatefulEither<S, L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, Either<L, A>>,
    _ rhs: Stateful<S, Either<L, B>>
) -> Stateful<S, Either<L, A>> {
    lhs.flatMapT { a in rhs.mapT(const(a)) }
}
