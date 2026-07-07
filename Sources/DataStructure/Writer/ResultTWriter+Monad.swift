// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// ResultTWriter: outer = Result, inner = Writer
// Type: Result<Writer<W, A>, E>

public extension Result {
    /// flatMapT :: Result<Writer<w, a>, e> -> (a -> Writer<w, b>) -> Result<Writer<w, b>, e>
    /// .failure(e)     → .failure(e)
    /// .success(writer) → .success(writer.flatMap(fn))
    func flatMapT<W: Monoid, A, B>(_ fn: (A) -> Writer<W, B>) -> Result<Writer<W, B>, Failure>
    where Success == Writer<W, A> {
        map { writer in writer.flatMap(fn) }
    }

    /// The `property` property.
    static func bindT<W: Monoid, A, B>(
        _ fn: @escaping @Sendable (A) -> Writer<W, B>
    ) -> (Result<Writer<W, A>, Failure>) -> Result<Writer<W, B>, Failure> {
        { result in result.flatMapT(fn) }
    }
}

/// Kleisli composition for `ResultT + Writer` (left-to-right)
/// (>=>) :: (a -> Result<Writer<w, b>, e>) -> (b -> Writer<w, c>) -> a -> Result<Writer<w, c>, e>
public func kleisliT<W: Monoid, A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> Result<Writer<W, B>, E>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, C>
) -> (A) -> Result<Writer<W, C>, E> {
    { a in fn1(a).flatMapT(fn2) }
}
