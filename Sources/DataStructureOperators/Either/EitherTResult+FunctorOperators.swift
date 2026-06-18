// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// EitherTResult: outer = Either, inner = Result
// Type: Either<L, Result<A,E>>

/// (<£^>) :: (a -> b) -> Either<l,Result<a,e>> -> Either<l,Result<b,e>>
public func <£^> <L, A, B, E: Error>(_ fn: @escaping @Sendable (A) -> B, _ either: Either<L, Result<A, E>>) -> Either<L, Result<B, E>> {
    fmapTEitherResult(fn)(either)
}

/// (<&^>) :: Either<l,Result<a,e>> -> (a -> b) -> Either<l,Result<b,e>>
public func <&^> <L, A, B, E: Error>(_ either: Either<L, Result<A, E>>, _ fn: @escaping @Sendable (A) -> B) -> Either<L, Result<B, E>> {
    fmapTEitherResult(fn)(either)
}
