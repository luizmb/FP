// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// StatefulT + Result — free functions for Stateful<S, Result<A, E>>

/// apply for Stateful<S, Result>
/// Equals `ap`: `sf >>= \f -> fmap f sa`. Sequential and short-circuiting like `flatMapT`:
/// when the function side fails, the right-hand state effect never happens.
public func applyStatefulResult<S, A, B, E: Error>(
    _ sf: Stateful<S, Result<@Sendable (A) -> B, E>>,
    _ sa: Stateful<S, Result<A, E>>
) -> Stateful<S, Result<B, E>> {
    sf.flatMapT { f in sa.mapT(f) }
}

/// liftA2 for Stateful<S, Result>
/// Equals `a >>= \x -> fmap (f x) b`. When `a` fails, `b`'s state effect never happens.
/// Inlined (same body as `flatMapT` + `mapT`) because `A` is not required to be `Sendable`.
public func liftA2StatefulResult<S, A, B, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Stateful<S, Result<A, E>>, Stateful<S, Result<B, E>>) -> Stateful<S, Result<C, E>> {
    { sa, sb in
        Stateful<S, Result<C, E>> { s in
            sa.run(&s).flatMap { a in sb.run(&s).map { b in fn(a, b) } }
        }
    }
}

/// seqRight for Stateful<S, Result>
/// Equals `a >>= \_ -> b`. When `lhs` fails, `rhs`'s state effect never happens.
public func seqRightStatefulResult<S, A, B, E: Error>(
    _ lhs: Stateful<S, Result<A, E>>,
    _ rhs: Stateful<S, Result<B, E>>
) -> Stateful<S, Result<B, E>> {
    lhs.flatMapT(const(rhs))
}

/// seqLeft for Stateful<S, Result>
/// Equals `a >>= \x -> fmap (const x) b`. When `lhs` fails, `rhs`'s state effect never happens.
/// Inlined (same body as `flatMapT` + `mapT`) because `A` is not required to be `Sendable`.
public func seqLeftStatefulResult<S, A, B, E: Error>(
    _ lhs: Stateful<S, Result<A, E>>,
    _ rhs: Stateful<S, Result<B, E>>
) -> Stateful<S, Result<A, E>> {
    Stateful<S, Result<A, E>> { s in
        lhs.run(&s).flatMap { a in rhs.run(&s).map(const(a)) }
    }
}
