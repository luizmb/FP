// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// NonEmptyTOptional: outer = NonEmpty, inner = Optional
// Type: NonEmpty<A?> = NonEmpty<Optional<A>>

/// apply for NonEmptyTOptional: NonEmpty<(A->B)?> -> NonEmpty<A?> -> NonEmpty<B?>
/// Cartesian product with Optional apply at each pair
public func applyNonEmptyOptional<A: Sendable, B: Sendable>(
    _ fns: NonEmpty<(@Sendable (A) -> B)?>,
    _ values: NonEmpty<A?>
) -> NonEmpty<B?> {
    fns.flatMap { f in values.map { a in f.flatMap { fn in a.map(fn) } } }
}

/// liftA2 for NonEmptyTOptional: (A,B)->C -> NonEmpty<A?> -> NonEmpty<B?> -> NonEmpty<C?>
public func liftA2NonEmptyOptional<A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (NonEmpty<A?>, NonEmpty<B?>) -> NonEmpty<C?> {
    { neA, neB in
        NonEmpty.liftA2 { @Sendable a, b in Optional.liftA2(fn)(a, b) }(neA, neB)
    }
}

/// seqRight for NonEmptyTOptional: NonEmpty<A?> -> NonEmpty<B?> -> NonEmpty<B?>
/// Cartesian product keeping right values (threading Optional through)
public func seqRightNonEmptyOptional<A: Sendable, B: Sendable>(_ lhs: NonEmpty<A?>, _ rhs: NonEmpty<B?>) -> NonEmpty<B?> {
    NonEmpty.liftA2 { (a: A?, b: B?) in a.seqRight(b) }(lhs, rhs)
}

/// seqLeft for NonEmptyTOptional: NonEmpty<A?> -> NonEmpty<B?> -> NonEmpty<A?>
public func seqLeftNonEmptyOptional<A: Sendable, B: Sendable>(_ lhs: NonEmpty<A?>, _ rhs: NonEmpty<B?>) -> NonEmpty<A?> {
    NonEmpty.liftA2 { (a: A?, b: B?) in a.seqLeft(b) }(lhs, rhs)
}
