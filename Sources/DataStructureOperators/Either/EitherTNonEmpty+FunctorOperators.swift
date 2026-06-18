// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// EitherTNonEmpty: outer = Either, inner = NonEmpty
// Type: Either<L, NonEmpty<A>>

/// (<£^>) :: (A -> B) -> Either<L, NonEmpty<A>> -> Either<L, NonEmpty<B>>
public func <£^> <L, A, B>(_ fn: @escaping @Sendable (A) -> B, _ either: Either<L, NonEmpty<A>>) -> Either<L, NonEmpty<B>> {
    fmapTEitherNonEmpty(fn)(either)
}

/// (<&^>) :: Either<L, NonEmpty<A>> -> (A -> B) -> Either<L, NonEmpty<B>>
public func <&^> <L, A, B>(_ either: Either<L, NonEmpty<A>>, _ fn: @escaping @Sendable (A) -> B) -> Either<L, NonEmpty<B>> {
    fmapTEitherNonEmpty(fn)(either)
}
