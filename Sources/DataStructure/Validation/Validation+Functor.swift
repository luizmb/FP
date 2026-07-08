// SPDX-License-Identifier: Apache-2.0
import CoreFP

public extension Validation {
    /// Curried, point-free form of ``mapSuccess(_:)`` — maps over the `.success` case, leaving `.failure` untouched.
    /// fmap :: (a -> b) -> Validation e a -> Validation e b
    static func fmap<B>(_ fn: @escaping @Sendable (A) -> B) -> @Sendable (Validation<E, A>) -> Validation<E, B> {
        { $0.mapSuccess(fn) }
    }

    /// Transforms the `.success` value, leaving `.failure` untouched (the `Functor.map` for `Validation`).
    /// fmap :: (a -> b) -> Validation e a -> Validation e b
    /// - Parameter fn: Function applied to the wrapped value when `self` is `.success`.
    /// - Returns: A new `Validation` with the transformed success type, unchanged if `self` is `.failure`.
    func mapSuccess<B>(_ fn: @escaping @Sendable (A) -> B) -> Validation<E, B> {
        match(
            caseFailure: Validation<E, B>.failure,
            caseSuccess: compose(fn, Validation<E, B>.success)
        )
    }

    /// Transforms the accumulated error(s), leaving `.success` untouched.
    /// mapFailure :: Semigroup e1 => (e -> e1) -> Validation e a -> Validation e1 a
    /// - Parameter fn: Function applied to the errors when `self` is `.failure`.
    /// - Returns: A new `Validation` with the transformed error type, unchanged if `self` is `.success`.
    func mapFailure<E1: Semigroup>(_ fn: @escaping @Sendable (E) -> E1) -> Validation<E1, A> {
        match(
            caseFailure: compose(fn, Validation<E1, A>.failure),
            caseSuccess: Validation<E1, A>.success
        )
    }

    /// Maps both sides of the `Validation` at once — the `Bifunctor.bimap` operation.
    /// bimap :: Semigroup e1 => (e -> e1) -> (a -> b) -> Validation e a -> Validation e1 b
    /// - Parameters:
    ///   - ef: Function applied to the errors when `self` is `.failure`.
    ///   - af: Function applied to the value when `self` is `.success`.
    /// - Returns: A `Validation` with both type parameters transformed.
    func bimap<E1: Semigroup, B>(_ ef: @escaping @Sendable (E) -> E1, _ af: @escaping @Sendable (A) -> B) -> Validation<E1, B> {
        match(
            caseFailure: compose(ef, Validation<E1, B>.failure),
            caseSuccess: compose(af, Validation<E1, B>.success)
        )
    }

    /// Discards the success value, keeping only the structure.
    /// void :: Validation e a -> Validation e ()
    func void() -> Validation<E, Void> {
        mapSuccess(ignore)
    }

    /// Curried, point-free form of ``bimap(_:_:)``.
    /// bimap :: Semigroup e1 => (e -> e1) -> (a -> b) -> Validation e a -> Validation e1 b
    static func bimap<E1: Semigroup, B>(
        _ ef: @escaping @Sendable (E) -> E1,
        _ af: @escaping @Sendable (A) -> B
    ) -> (Validation<E, A>) -> Validation<E1, B> {
        { $0.bimap(ef, af) }
    }
}
