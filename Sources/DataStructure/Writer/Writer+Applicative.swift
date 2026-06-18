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

    /// Declaration.
    func seqRight<B>(_ other: Writer<W, B>) -> Writer<W, B> {
        Writer<W, B>(other.value, W.combine(log, other.log))
    }

    /// Declaration.
    func seqLeft<B>(_ other: Writer<W, B>) -> Writer<W, A> {
        Writer<W, A>(value, W.combine(log, other.log))
    }

    /// The `property` property.
    static func liftA2<B, C>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> @Sendable (Writer<W, A>, Writer<W, B>) -> Writer<W, C> {
        { wa, wb in
            Writer<W, C>(fn(wa.value, wb.value), W.combine(wa.log, wb.log))
        }
    }

    /// zip :: Writer<w, a1> -> Writer<w, a2> -> Writer<w, (a1, a2)>
    /// Combines logs left-to-right via Monoid.combine.
    static func zip<A1, A2>(_ wa1: Writer<W, A1>, _ wa2: Writer<W, A2>) -> Writer<W, A>
    where A == (A1, A2) {
        Writer<W, (A1, A2)>((wa1.value, wa2.value), W.combine(wa1.log, wa2.log))
    }

    /// zip3 :: Writer<w, a1> -> Writer<w, a2> -> Writer<w, a3> -> Writer<w, (a1, a2, a3)>
    /// Combines logs left-to-right via Monoid.combine.
    static func zip3<A1, A2, A3>(
        _ wa1: Writer<W, A1>,
        _ wa2: Writer<W, A2>,
        _ wa3: Writer<W, A3>
    ) -> Writer<W, A>
    where A == (A1, A2, A3) {
        Writer<W, (A1, A2, A3)>(
            (wa1.value, wa2.value, wa3.value),
            W.combine(W.combine(wa1.log, wa2.log), wa3.log)
        )
    }

    /// zip4 :: Writer<w, a1> -> … -> Writer<w, a4> -> Writer<w, (a1, a2, a3, a4)>
    /// Combines logs left-to-right via Monoid.combine.
    static func zip4<A1, A2, A3, A4>(
        _ wa1: Writer<W, A1>,
        _ wa2: Writer<W, A2>,
        _ wa3: Writer<W, A3>,
        _ wa4: Writer<W, A4>
    ) -> Writer<W, A>
    where A == (A1, A2, A3, A4) {
        Writer<W, (A1, A2, A3, A4)>(
            (wa1.value, wa2.value, wa3.value, wa4.value),
            W.combine(W.combine(W.combine(wa1.log, wa2.log), wa3.log), wa4.log)
        )
    }
}
