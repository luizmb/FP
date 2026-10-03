// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// `M<Writer<W, A>>` is Haskell's `WriterT w M`. Its composed applicative must equal WriterT's
// `ap` derived from the bind: `ap mf ma = mf >>= \f -> fmap f ma`.

private typealias W = Writer<[String], Int>
private typealias WF = Writer<[String], @Sendable (Int) -> Int>

private struct Boom: Error, Equatable {}

private let plusOne: @Sendable (Int) -> Int = { $0 + 1 }
private let timesTen: @Sendable (Int) -> Int = { $0 * 10 }
private let idInt: @Sendable (Int) -> Int = id
private let keepRight: @Sendable (Int) -> @Sendable (Int) -> Int = const(idInt)
private let keepLeft: @Sendable (Int) -> @Sendable (Int) -> Int = const

private func apArray(_ fns: [WF], _ vals: [W]) -> [W] {
    fns.flatMapT { fn in vals.mapT(fn) }
}

private func apOptional(_ fn: WF?, _ val: W?) -> W? {
    fn.flatMapT { fn in val.mapT(fn) }
}

private func apResult(_ fn: Result<WF, Boom>, _ val: Result<W, Boom>) -> Result<W, Boom> {
    fn.flatMapT { fn in val.mapT(fn) }
}

private func apEither(_ fn: Either<String, WF>, _ val: Either<String, W>) -> Either<String, W> {
    fn.flatMapT { fn in val.mapT(fn) }
}

@Suite("M<Writer> applicatives equal WriterT ap")
struct WriterInnerApConsistencyTests {
    @Test func arrayTWriterApplyIsWriterTAp() {
        let fns: [WF] = [WF(plusOne, ["f"]), WF(timesTen, ["g"])]
        let vals: [W] = [W(1, ["a"]), W(2, ["b"])]
        #expect(applyArrayWriter(fns, vals) == apArray(fns, vals))
        #expect(applyArrayWriter(fns, vals) == [W(2, ["f", "a"]), W(3, ["f", "b"]), W(10, ["g", "a"]), W(20, ["g", "b"])])
        #expect(applyArrayWriter([WF](), vals) == apArray([], vals))
        #expect(applyArrayWriter(fns, [W]()) == apArray(fns, []))
        #expect(seqRightArrayWriter(vals, vals) == apArray(vals.mapT(keepRight), vals))
        #expect(seqLeftArrayWriter(vals, vals) == apArray(vals.mapT(keepLeft), vals))
    }

    @Test func optionalTWriterApplyIsWriterTAp() {
        let fn: WF? = WF(plusOne, ["f"])
        let val: W? = W(1, ["a"])
        for (lhs, rhs) in [(fn, val), (nil, val), (fn, nil), (nil, nil)] {
            #expect(applyOptionalWriter(lhs, rhs) == apOptional(lhs, rhs))
        }
        #expect(applyOptionalWriter(fn, val) == W(2, ["f", "a"]))
        #expect(seqRightOptionalWriter(val, val) == apOptional(val.mapT(keepRight), val))
        #expect(seqLeftOptionalWriter(val, val) == apOptional(val.mapT(keepLeft), val))
    }

    @Test func resultTWriterApplyIsWriterTAp() {
        let fn: Result<WF, Boom> = .success(WF(plusOne, ["f"]))
        let val: Result<W, Boom> = .success(W(1, ["a"]))
        let failedFn: Result<WF, Boom> = .failure(Boom())
        let failedVal: Result<W, Boom> = .failure(Boom())
        for (lhs, rhs) in [(fn, val), (failedFn, val), (fn, failedVal), (failedFn, failedVal)] {
            #expect(applyResultWriter(lhs, rhs) == apResult(lhs, rhs))
        }
        #expect(applyResultWriter(fn, val) == .success(W(2, ["f", "a"])))
        #expect(seqRightResultWriter(val, val) == apResult(val.mapT(keepRight), val))
        #expect(seqLeftResultWriter(val, val) == apResult(val.mapT(keepLeft), val))
    }

    @Test func eitherTWriterApplyIsWriterTAp() {
        let fn: Either<String, WF> = .right(WF(plusOne, ["f"]))
        let val: Either<String, W> = .right(W(1, ["a"]))
        let failedFn: Either<String, WF> = .left("fn")
        let failedVal: Either<String, W> = .left("val")
        for (lhs, rhs) in [(fn, val), (failedFn, val), (fn, failedVal), (failedFn, failedVal)] {
            #expect(applyEitherWriter(lhs, rhs) == apEither(lhs, rhs))
        }
        #expect(applyEitherWriter(fn, val) == .right(W(2, ["f", "a"])))
        #expect(applyEitherWriter(failedFn, failedVal) == .left("fn"))
        #expect(seqRightEitherWriter(val, val) == apEither(val.mapT(keepRight), val))
        #expect(seqLeftEitherWriter(val, val) == apEither(val.mapT(keepLeft), val))
    }
}
