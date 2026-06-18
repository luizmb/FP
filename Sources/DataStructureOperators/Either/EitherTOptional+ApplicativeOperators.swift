// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// EitherTOptional: outer = Either, inner = Optional
// Type: Either<L, A?>

/// (<*>) :: Either<l,(a->b)?> -> Either<l,a?> -> Either<l,b?>
public func <*> <L, A, B>(_ fns: Either<L, (@Sendable (A) -> B)?>, _ values: Either<L, A?>) -> Either<L, B?> {
    applyEitherOptional(fns, values)
}

/// (*>) :: Either<l,a?> -> Either<l,b?> -> Either<l,b?>
public func *> <L, A, B>(_ lhs: Either<L, A?>, _ rhs: Either<L, B?>) -> Either<L, B?> where L: Sendable, A: Sendable, B: Sendable {
    seqRightEitherOptional(lhs, rhs)
}

/// (<*) :: Either<l,a?> -> Either<l,b?> -> Either<l,a?>
public func <* <L, A, B>(_ lhs: Either<L, A?>, _ rhs: Either<L, B?>) -> Either<L, A?> where L: Sendable, A: Sendable, B: Sendable {
    seqLeftEitherOptional(lhs, rhs)
}
