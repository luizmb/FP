// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// StatefulT + Optional — free functions for Stateful<S, A?>

/// apply for Stateful<S, Optional>
/// Equals `ap`: `sf >>= \f -> fmap f sa`. Sequential and short-circuiting like `flatMapT`:
/// when the function side fails, the right-hand state effect never happens.
public func applyStatefulOptional<S, A, B>(
    _ sf: Stateful<S, (@Sendable (A) -> B)?>,
    _ sa: Stateful<S, A?>
) -> Stateful<S, B?> {
    sf.flatMapT { f in sa.mapT(f) }
}

/// liftA2 for Stateful<S, Optional>
/// Equals `a >>= \x -> fmap (f x) b`. When `a` fails, `b`'s state effect never happens.
public func liftA2StatefulOptional<S, A: Sendable, B: Sendable, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (Stateful<S, A?>, Stateful<S, B?>) -> Stateful<S, C?> {
    { sa, sb in sa.flatMapT { a in sb.mapT { b in fn(a, b) } } }
}

/// seqRight for Stateful<S, Optional>
/// Equals `a >>= \_ -> b`. When `lhs` fails, `rhs`'s state effect never happens.
public func seqRightStatefulOptional<S, A, B>(
    _ lhs: Stateful<S, A?>,
    _ rhs: Stateful<S, B?>
) -> Stateful<S, B?> {
    lhs.flatMapT(const(rhs))
}

/// seqLeft for Stateful<S, Optional>
/// Equals `a >>= \x -> fmap (const x) b`. When `lhs` fails, `rhs`'s state effect never happens.
public func seqLeftStatefulOptional<S, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, A?>,
    _ rhs: Stateful<S, B?>
) -> Stateful<S, A?> {
    lhs.flatMapT { a in rhs.mapT(const(a)) }
}
