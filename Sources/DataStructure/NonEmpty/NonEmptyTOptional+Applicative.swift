// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// NonEmptyTOptional: outer = NonEmpty, inner = Optional
// Type: NonEmpty<A?> = NonEmpty<Optional<A>>
// Haskell: MaybeT NonEmpty
//
// The applicative is derived from the monad (`<*>` = `ap`): sequential and short-circuiting
// exactly like `flatMapT`. A `nil` on the left yields a single `nil` and never runs the right side.

/// apply for NonEmptyTOptional: NonEmpty<(A->B)?> -> NonEmpty<A?> -> NonEmpty<B?>
/// mf <*> ma = mf >>= \f -> fmap f ma
func applyNonEmptyOptional<A: Sendable, B: Sendable>(
    _ fns: NonEmpty<(@Sendable (A) -> B)?>,
    _ values: NonEmpty<A?>
) -> NonEmpty<B?> {
    fns.flatMapT { f in values.mapT(f) }
}

/// liftA2 for NonEmptyTOptional: (A,B)->C -> NonEmpty<A?> -> NonEmpty<B?> -> NonEmpty<C?>
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
func liftA2NonEmptyOptional<A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (NonEmpty<A?>, NonEmpty<B?>) -> NonEmpty<C?> {
    { neA, neB in
        neA.flatMapT { a in neB.mapT { b in fn(a, b) } }
    }
}

/// seqRight for NonEmptyTOptional: NonEmpty<A?> -> NonEmpty<B?> -> NonEmpty<B?>
/// ma *> mb = ma >>= \_ -> mb
func seqRightNonEmptyOptional<A: Sendable, B: Sendable>(_ lhs: NonEmpty<A?>, _ rhs: NonEmpty<B?>) -> NonEmpty<B?> {
    lhs.flatMapT { (_: A) in rhs }
}

/// seqLeft for NonEmptyTOptional: NonEmpty<A?> -> NonEmpty<B?> -> NonEmpty<A?>
/// ma <* mb = ma >>= \a -> fmap (const a) mb
func seqLeftNonEmptyOptional<A: Sendable, B: Sendable>(_ lhs: NonEmpty<A?>, _ rhs: NonEmpty<B?>) -> NonEmpty<A?> {
    lhs.flatMapT { a in rhs.mapT { (_: B) in a } }
}
