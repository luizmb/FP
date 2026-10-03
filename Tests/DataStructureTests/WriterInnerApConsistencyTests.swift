// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// `M<Writer<W, A>>` is Haskell's `WriterT w M`. Its composed applicative must equal WriterT's
// `ap` (run `M` left to right, combine logs left to right). These stacks' current `flatMapT`
// takes an inner-only continuation, so the reference `ap` is written out here instead.

private typealias W = Writer<[String], Int>
private typealias WF = Writer<[String], @Sendable (Int) -> Int>

private let plusOne: @Sendable (Int) -> Int = { $0 + 1 }
private let timesTen: @Sendable (Int) -> Int = { $0 * 10 }

private func combined(_ wf: WF, _ wa: W) -> W {
    W(wf.value(wa.value), wf.log + wa.log)
}

@Suite("M<Writer> applicatives equal WriterT ap")
struct WriterInnerApConsistencyTests {
    @Test func arrayTWriterApplyIsWriterTAp() {
        let fns: [WF] = [WF(plusOne, ["f"]), WF(timesTen, ["g"])]
        let vals: [W] = [W(1, ["a"]), W(2, ["b"])]
        let expected = fns.flatMap { wf in vals.map { wa in combined(wf, wa) } }
        #expect(applyArrayWriter(fns, vals) == expected)
        #expect(applyArrayWriter([WF](), vals).isEmpty)
        #expect(applyArrayWriter(fns, [W]()).isEmpty)
    }

    @Test func optionalTWriterApplyIsWriterTAp() {
        let fn: WF? = WF(plusOne, ["f"])
        let val: W? = W(1, ["a"])
        #expect(applyOptionalWriter(fn, val) == W(2, ["f", "a"]))
        #expect(applyOptionalWriter(nil as WF?, val) == nil)
        #expect(applyOptionalWriter(fn, nil as W?) == nil)
    }

    @Test func resultTWriterApplyIsWriterTAp() {
        struct Boom: Error, Equatable {}
        let fn: Result<WF, Boom> = .success(WF(plusOne, ["f"]))
        let val: Result<W, Boom> = .success(W(1, ["a"]))
        #expect(applyResultWriter(fn, val) == .success(W(2, ["f", "a"])))
        #expect(applyResultWriter(Result<WF, Boom>.failure(Boom()), val) == .failure(Boom()))
        #expect(applyResultWriter(fn, Result<W, Boom>.failure(Boom())) == .failure(Boom()))
    }
}
