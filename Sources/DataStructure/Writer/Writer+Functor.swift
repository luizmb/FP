// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Writer {
    /// Transforms the computed value, leaving the log untouched — named after the classic Haskell Writer API.
    /// fmap :: (a -> b) -> Writer w a -> Writer w b
    func mapWriter<B>(_ fn: (A) -> B) -> Writer<W, B> {
        Writer<W, B>(fn(value), log)
    }

    /// Transforms the computed value, leaving the log untouched (the `Functor.map` for `Writer`).
    /// fmap :: (a -> b) -> Writer w a -> Writer w b
    func map<B>(_ fn: (A) -> B) -> Writer<W, B> {
        mapWriter(fn)
    }

    /// Curried, point-free form of ``map(_:)``.
    /// fmap :: (a -> b) -> Writer w a -> Writer w b
    static func fmap<B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Writer<W, A>) -> Writer<W, B> {
        { $0.mapWriter(fn) }
    }
}
