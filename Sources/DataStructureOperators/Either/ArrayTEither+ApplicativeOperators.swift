// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// ArrayTEither: outer = Array, inner = Either
// Type: [Either<L,A>]

/// (<*>) :: [Either<l,(a->b)>] -> [Either<l,a>] -> [Either<l,b>]
public func <*> <L: Sendable, A: Sendable, B: Sendable>(
    _ fns: [Either<L, @Sendable (A) -> B>],
    _ values: [Either<L, A>]
) -> [Either<L, B>] {
    applyArrayEither(fns, values)
}

/// (*>) :: [Either<l,a>] -> [Either<l,b>] -> [Either<l,b>]
public func *> <L: Sendable, A: Sendable, B: Sendable>(_ lhs: [Either<L, A>], _ rhs: [Either<L, B>]) -> [Either<L, B>] {
    seqRightArrayEither(lhs, rhs)
}

/// (<*) :: [Either<l,a>] -> [Either<l,b>] -> [Either<l,a>]
public func <* <L: Sendable, A: Sendable, B: Sendable>(_ lhs: [Either<L, A>], _ rhs: [Either<L, B>]) -> [Either<L, A>] {
    seqLeftArrayEither(lhs, rhs)
}
