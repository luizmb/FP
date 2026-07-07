// SPDX-License-Identifier: Apache-2.0
// NonEmptyTResult: outer = NonEmpty, inner = Result
// Type: NonEmpty<Result<A, E>>  (Success = A, Failure = E)

/// Cartesian product across the `NonEmpty` structure, combining each pair element-wise.
/// Result is always non-empty since both inputs are non-empty.
private func cartesianNonEmpty<X, Y, Z>(
    _ nx: NonEmpty<X>,
    _ ny: NonEmpty<Y>,
    _ combine: (X, Y) -> Z
) -> NonEmpty<Z> {
    let all = nx.toArray.flatMap { x in ny.toArray.map { y in combine(x, y) } }
    return NonEmpty(head: all[0], tail: Array(all.dropFirst()))
}

/// apply for NonEmptyTResult: NonEmpty<Result<(A->B),E>> -> NonEmpty<Result<A,E>> -> NonEmpty<Result<B,E>>
/// Cartesian product of NonEmpty, applying Result.apply pairwise.
public func applyNonEmptyResult<A, B, E>(
    _ fns: NonEmpty<Result<@Sendable (A) -> B, E>>,
    _ values: NonEmpty<Result<A, E>>
) -> NonEmpty<Result<B, E>> {
    cartesianNonEmpty(fns, values, Result.apply)
}

/// liftA2 for NonEmptyTResult: (A,B)->C -> NonEmpty<Result<A,E>> -> NonEmpty<Result<B,E>> -> NonEmpty<Result<C,E>>
public func liftA2NonEmptyResult<A, B, C, E>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (NonEmpty<Result<A, E>>, NonEmpty<Result<B, E>>) -> NonEmpty<Result<C, E>> {
    { neA, neB in cartesianNonEmpty(neA, neB, Result.liftA2(fn)) }
}

/// seqRight for NonEmptyTResult: NonEmpty<Result<A,E>> -> NonEmpty<Result<B,E>> -> NonEmpty<Result<B,E>>
public func seqRightNonEmptyResult<A, B, E>(
    _ lhs: NonEmpty<Result<A, E>>,
    _ rhs: NonEmpty<Result<B, E>>
) -> NonEmpty<Result<B, E>> {
    cartesianNonEmpty(lhs, rhs) { a, b in a.seqRight(b) }
}

/// seqLeft for NonEmptyTResult: NonEmpty<Result<A,E>> -> NonEmpty<Result<B,E>> -> NonEmpty<Result<A,E>>
public func seqLeftNonEmptyResult<A, B, E>(
    _ lhs: NonEmpty<Result<A, E>>,
    _ rhs: NonEmpty<Result<B, E>>
) -> NonEmpty<Result<A, E>> {
    cartesianNonEmpty(lhs, rhs) { a, b in a.seqLeft(b) }
}
