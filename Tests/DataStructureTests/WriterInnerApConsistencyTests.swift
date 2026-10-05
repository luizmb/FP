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
    fns.arrayT.flatMap { fn in vals.arrayT.map(fn) }.rawValue
}

private func apOptional(_ fn: WF?, _ val: W?) -> W? {
    fn.optionalT.flatMap { fn in val.optionalT.map(fn) }.rawValue
}

private func apResult(_ fn: Result<WF, Boom>, _ val: Result<W, Boom>) -> Result<W, Boom> {
    fn.resultT.flatMap { fn in val.resultT.map(fn) }.rawValue
}

private func apEither(_ fn: Either<String, WF>, _ val: Either<String, W>) -> Either<String, W> {
    fn.eitherT.flatMap { fn in val.eitherT.map(fn) }.rawValue
}

@Suite("M<Writer> applicatives equal WriterT ap")
struct WriterInnerApConsistencyTests {
    @Test func arrayTWriterApplyIsWriterTAp() {
        let fns: [WF] = [WF(plusOne, ["f"]), WF(timesTen, ["g"])]
        let vals: [W] = [W(1, ["a"]), W(2, ["b"])]
        #expect(ArrayTWriter.apply(fns.arrayT, vals.arrayT).rawValue == apArray(fns, vals))
        let expected = [W(2, ["f", "a"]), W(3, ["f", "b"]), W(10, ["g", "a"]), W(20, ["g", "b"])]
        #expect(ArrayTWriter.apply(fns.arrayT, vals.arrayT).rawValue == expected)
        #expect(ArrayTWriter.apply([WF]().arrayT, vals.arrayT).rawValue == apArray([], vals))
        #expect(ArrayTWriter.apply(fns.arrayT, [W]().arrayT).rawValue == apArray(fns, []))
        #expect(vals.arrayT.seqRight(vals.arrayT).rawValue == apArray(vals.arrayT.map(keepRight).rawValue, vals))
        #expect(vals.arrayT.seqLeft(vals.arrayT).rawValue == apArray(vals.arrayT.map(keepLeft).rawValue, vals))
    }

    @Test func optionalTWriterApplyIsWriterTAp() {
        let fn: WF? = WF(plusOne, ["f"])
        let val: W? = W(1, ["a"])
        for (lhs, rhs) in [(fn, val), (nil, val), (fn, nil), (nil, nil)] {
            #expect(OptionalTWriter.apply(lhs.optionalT, rhs.optionalT).rawValue == apOptional(lhs, rhs))
        }
        #expect(OptionalTWriter.apply(fn.optionalT, val.optionalT).rawValue == W(2, ["f", "a"]))
        #expect(val.optionalT.seqRight(val.optionalT).rawValue == apOptional(val.optionalT.map(keepRight).rawValue, val))
        #expect(val.optionalT.seqLeft(val.optionalT).rawValue == apOptional(val.optionalT.map(keepLeft).rawValue, val))
    }

    @Test func resultTWriterApplyIsWriterTAp() {
        let fn: Result<WF, Boom> = .success(WF(plusOne, ["f"]))
        let val: Result<W, Boom> = .success(W(1, ["a"]))
        let failedFn: Result<WF, Boom> = .failure(Boom())
        let failedVal: Result<W, Boom> = .failure(Boom())
        for (lhs, rhs) in [(fn, val), (failedFn, val), (fn, failedVal), (failedFn, failedVal)] {
            #expect(ResultTWriter.apply(lhs.resultT, rhs.resultT).rawValue == apResult(lhs, rhs))
        }
        #expect(ResultTWriter.apply(fn.resultT, val.resultT).rawValue == .success(W(2, ["f", "a"])))
        #expect(val.resultT.seqRight(val.resultT).rawValue == apResult(val.resultT.map(keepRight).rawValue, val))
        #expect(val.resultT.seqLeft(val.resultT).rawValue == apResult(val.resultT.map(keepLeft).rawValue, val))
    }

    @Test func eitherTWriterApplyIsWriterTAp() {
        let fn: Either<String, WF> = .right(WF(plusOne, ["f"]))
        let val: Either<String, W> = .right(W(1, ["a"]))
        let failedFn: Either<String, WF> = .left("fn")
        let failedVal: Either<String, W> = .left("val")
        for (lhs, rhs) in [(fn, val), (failedFn, val), (fn, failedVal), (failedFn, failedVal)] {
            #expect(EitherTWriter.apply(lhs.eitherT, rhs.eitherT).rawValue == apEither(lhs, rhs))
        }
        #expect(EitherTWriter.apply(fn.eitherT, val.eitherT).rawValue == .right(W(2, ["f", "a"])))
        #expect(EitherTWriter.apply(failedFn.eitherT, failedVal.eitherT).rawValue == .left("fn"))
        #expect(val.eitherT.seqRight(val.eitherT).rawValue == apEither(val.eitherT.map(keepRight).rawValue, val))
        #expect(val.eitherT.seqLeft(val.eitherT).rawValue == apEither(val.eitherT.map(keepLeft).rawValue, val))
    }
}
