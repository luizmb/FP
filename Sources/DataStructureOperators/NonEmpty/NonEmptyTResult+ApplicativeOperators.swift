// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// MARK: - Transformer applicative operators: NonEmpty<Result<A, E>>

/// (<*>) :: NonEmpty<Result<(A->B),E>> -> NonEmpty<Result<A,E>> -> NonEmpty<Result<B,E>>
public func <*> <A, B, E>(
    _ fns: NonEmpty<Result<@Sendable (A) -> B, E>>,
    _ values: NonEmpty<Result<A, E>>
) -> NonEmpty<Result<B, E>> {
    applyNonEmptyResult(fns, values)
}

/// (*>) :: NonEmpty<Result<A,E>> -> NonEmpty<Result<B,E>> -> NonEmpty<Result<B,E>>
public func *> <A, B, E>(
    _ lhs: NonEmpty<Result<A, E>>,
    _ rhs: NonEmpty<Result<B, E>>
) -> NonEmpty<Result<B, E>> {
    seqRightNonEmptyResult(lhs, rhs)
}

/// (<*) :: NonEmpty<Result<A,E>> -> NonEmpty<Result<B,E>> -> NonEmpty<Result<A,E>>
public func <* <A, B, E>(
    _ lhs: NonEmpty<Result<A, E>>,
    _ rhs: NonEmpty<Result<B, E>>
) -> NonEmpty<Result<A, E>> {
    seqLeftNonEmptyResult(lhs, rhs)
}
