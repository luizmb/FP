// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// ResultTWriter: outer = Result, inner = Writer
// Type: Result<Writer<W, A>, E>  (Haskell: WriterT w (Either e) a)
//
// flatMapT is WriterT's bind: the continuation returns the full stack, so it can fail
// (`.failure`) as well as log. `.failure` short-circuits; logs combine left to right.

extension Result {
    /// flatMapT :: Result<Writer<w, a>, e> -> (a -> Result<Writer<w, b>, e>) -> Result<Writer<w, b>, e>
    /// .failure(e)  → .failure(e)
    /// .success(w1) → fn(w1.value): .failure(e) → .failure(e); .success(w2) → .success(Writer(w2.value, w1.log <> w2.log))
    func flatMapT<W: Monoid, A, B>(_ fn: (A) -> Result<Writer<W, B>, Failure>) -> Result<Writer<W, B>, Failure>
    where Success == Writer<W, A> {
        flatMap { w1 in fn(w1.value).map { w2 in Writer(w2.value, W.combine(w1.log, w2.log)) } }
    }

    /// bindT :: (a -> Result<Writer<w, b>, e>) -> Result<Writer<w, a>, e> -> Result<Writer<w, b>, e>
    static func bindT<W: Monoid, A, B>(
        _ fn: @escaping @Sendable (A) -> Result<Writer<W, B>, Failure>
    ) -> @Sendable (Result<Writer<W, A>, Failure>) -> Result<Writer<W, B>, Failure> {
        { result in result.flatMapT(fn) }
    }
}

/// Kleisli composition for `ResultT + Writer` (left-to-right)
/// (>=>) :: (a -> Result<Writer<w, b>, e>) -> (b -> Result<Writer<w, c>, e>) -> a -> Result<Writer<w, c>, e>
func kleisliT<W: Monoid, A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> Result<Writer<W, B>, E>,
    _ fn2: @escaping @Sendable (B) -> Result<Writer<W, C>, E>
) -> @Sendable (A) -> Result<Writer<W, C>, E> {
    { a in fn1(a).flatMapT(fn2) }
}
