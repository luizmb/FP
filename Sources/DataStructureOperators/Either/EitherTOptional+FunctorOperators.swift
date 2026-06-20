// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// EitherTOptional: outer = Either, inner = Optional
// Type: Either<L, A?>

/// (<£^>) :: (a -> b) -> Either<l,a?> -> Either<l,b?>
public func <£^> <L, A, B>(_ fn: @escaping @Sendable (A) -> B, _ either: Either<L, A?>) -> Either<L, B?> {
    fmapTEitherOptional(fn)(either)
}

/// (<&^>) :: Either<l,a?> -> (a -> b) -> Either<l,b?>
public func <&^> <L, A, B>(_ either: Either<L, A?>, _ fn: @escaping @Sendable (A) -> B) -> Either<L, B?> {
    fmapTEitherOptional(fn)(either)
}
