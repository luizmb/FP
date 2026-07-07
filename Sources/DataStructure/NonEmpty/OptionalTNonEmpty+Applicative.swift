// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// OptionalTNonEmpty: outer = Optional, inner = NonEmpty
// Type: NonEmpty<A>? = Optional<NonEmpty<A>>

/// apply for OptionalTNonEmpty: NonEmpty<(A->B)>? -> NonEmpty<A>? -> NonEmpty<B>?
/// If outer is nil → nil; otherwise use NonEmpty.apply (cartesian product)
public func applyOptionalNonEmpty<A: Sendable, B: Sendable>(
    _ fns: NonEmpty<@Sendable (A) -> B>?,
    _ values: NonEmpty<A>?
) -> NonEmpty<B>? {
    fns.flatMap { nf in values.map { na in NonEmpty.apply(nf, na) } }
}

/// liftA2 for OptionalTNonEmpty: (A,B)->C -> NonEmpty<A>? -> NonEmpty<B>? -> NonEmpty<C>?
public func liftA2OptionalNonEmpty<A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (NonEmpty<A>?, NonEmpty<B>?) -> NonEmpty<C>? {
    Optional.liftA2(NonEmpty.liftA2(fn))
}

/// seqRight for OptionalTNonEmpty: NonEmpty<A>? -> NonEmpty<B>? -> NonEmpty<B>?
public func seqRightOptionalNonEmpty<A, B>(_ lhs: NonEmpty<A>?, _ rhs: NonEmpty<B>?) -> NonEmpty<B>? {
    lhs.seqRight(rhs)
}

/// seqLeft for OptionalTNonEmpty: NonEmpty<A>? -> NonEmpty<B>? -> NonEmpty<A>?
public func seqLeftOptionalNonEmpty<A, B>(_ lhs: NonEmpty<A>?, _ rhs: NonEmpty<B>?) -> NonEmpty<A>? {
    lhs.seqLeft(rhs)
}
