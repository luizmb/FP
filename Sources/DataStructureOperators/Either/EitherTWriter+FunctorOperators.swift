// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

// EitherTWriter: outer = Either, inner = Writer
// Type: Either<L, Writer<W, A>>

/// (<£^>) :: (a -> b) -> Either<l, Writer<w, a>> -> Either<l, Writer<w, b>>
public func <£^> <L, W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> B, _ either: Either<L, Writer<W, A>>) -> Either<L, Writer<W, B>> {
    either.mapT(fn)
}

/// (<&^>) :: Either<l, Writer<w, a>> -> (a -> b) -> Either<l, Writer<w, b>>
public func <&^> <L, W: Monoid, A, B>(_ either: Either<L, Writer<W, A>>, _ fn: @escaping @Sendable (A) -> B) -> Either<L, Writer<W, B>> {
    either.mapT(fn)
}
