// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Writer {
    /// apply :: Writer<w, (input -> a)> -> Writer<w, input> -> Writer<w, a>
    /// Applies the function and combines logs left-to-right.
    /// Follows Reader/Stateful convention: `A` is the result type, `Input` is the argument type.
    static func apply<Input>(_ wf: Writer<W, @Sendable (Input) -> A>, _ wa: Writer<W, Input>) -> Writer<W, A> {
        Writer<W, A>(wf.value(wa.value), W.combine(wf.log, wa.log))
    }

    /// seqRight :: Writer<w, a> -> Writer<w, b> -> Writer<w, b>
    /// Runs both, combining logs left-to-right, and keeps only the right-hand value.
    func seqRight<B>(_ other: Writer<W, B>) -> Writer<W, B> {
        Writer<W, B>(other.value, W.combine(log, other.log))
    }

    /// seqLeft :: Writer<w, a> -> Writer<w, b> -> Writer<w, a>
    /// Runs both, combining logs left-to-right, and keeps only the left-hand value.
    func seqLeft<B>(_ other: Writer<W, B>) -> Writer<W, A> {
        Writer<W, A>(value, W.combine(log, other.log))
    }

    /// Combines two `Writer` values with a binary function, merging their logs via `Monoid.combine`.
    /// liftA2 :: (a -> b -> c) -> Writer w a -> Writer w b -> Writer w c
    static func liftA2<B, C>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> @Sendable (Writer<W, A>, Writer<W, B>) -> Writer<W, C> {
        { wa, wb in
            Writer<W, C>(fn(wa.value, wb.value), W.combine(wa.log, wb.log))
        }
    }

    /// Combines two or more `Writer`s into one producing a tuple of all their values,
    /// combining the logs left to right via `Monoid.combine`.
    /// zip :: Writer w a1 -> Writer w a2 -> ... -> Writer w (a1, a2, ...)
    static func zip<A1, A2, each Ax>(
        _ first: Writer<W, A1>,
        _ second: Writer<W, A2>,
        _ additional: repeat Writer<W, each Ax>
    ) -> Writer<W, A>
    where A == (A1, A2, repeat each Ax) {
        var log = W.combine(first.log, second.log)
        for writer in repeat each additional {
            log = W.combine(log, writer.log)
        }
        return Writer<W, A>((first.value, second.value, repeat (each additional).value), log)
    }
}
