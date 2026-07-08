// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Either {
    /// Curried, point-free form of ``mapRight(_:)`` — maps over the `.right` case, leaving `.left` untouched.
    /// fmap :: (b -> b1) -> Either a b -> Either a b1
    static func fmap<B1>(
        _ fn: @escaping @Sendable (B) -> B1
    ) -> @Sendable (Either<A, B>) -> Either<A, B1> {
        { $0.mapRight(fn) }
    }

    /// Transforms the `.left` value, leaving `.right` untouched.
    /// mapLeft :: (a -> a1) -> Either a b -> Either a1 b
    /// - Parameter lf: Function applied to the wrapped value when `self` is `.left`.
    /// - Returns: A new `Either` with the transformed left type, unchanged if `self` is `.right`.
    func mapLeft<A1>(
        _ lf: @escaping @Sendable (A) -> A1
    ) -> Either<A1, B> {
        match(
            caseLeft: compose(lf, Either<A1, B>.left),
            caseRight: Either<A1, B>.right
        )
    }

    /// Transforms the `.right` value, leaving `.left` untouched (the `Functor.map` for `Either`).
    /// fmap :: (b -> b1) -> Either a b -> Either a b1
    /// - Parameter rf: Function applied to the wrapped value when `self` is `.right`.
    /// - Returns: A new `Either` with the transformed right type, unchanged if `self` is `.left`.
    func mapRight<B1>(
        _ rf: @escaping @Sendable (B) -> B1
    ) -> Either<A, B1> {
        match(
            caseLeft: Either<A, B1>.left,
            caseRight: compose(rf, Either<A, B1>.right)
        )
    }

    /// Maps both sides of the `Either` at once — the `Bifunctor.bimap` operation.
    /// bimap :: (a -> a1) -> (b -> b1) -> Either a b -> Either a1 b1
    /// - Parameters:
    ///   - lf: Function applied when `self` is `.left`.
    ///   - rf: Function applied when `self` is `.right`.
    /// - Returns: An `Either` with both type parameters transformed.
    func bimap<A1, B1>(
        _ lf: @escaping @Sendable (A) -> A1,
        _ rf: @escaping @Sendable (B) -> B1
    ) -> Either<A1, B1> {
        match(
            caseLeft: compose(lf, Either<A1, B1>.left),
            caseRight: compose(rf, Either<A1, B1>.right)
        )
    }

    /// Curried, point-free form of ``bimap(_:_:)``.
    /// bimap :: (a -> a1) -> (b -> b1) -> Either a b -> Either a1 b1
    static func bimap<A1, B1>(
        _ lf: @escaping @Sendable (A) -> A1,
        _ rf: @escaping @Sendable (B) -> B1
    ) -> (Either<A, B>) -> Either<A1, B1> {
        { $0.bimap(lf, rf) }
    }
}
