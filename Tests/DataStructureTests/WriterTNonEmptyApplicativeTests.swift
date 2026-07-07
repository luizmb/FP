// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct WriterTNonEmptyApplicativeTests {
    // MARK: - apply

    @Test func applyCombinesFunctionsAndValues() {
        let wf = Writer<[String], NonEmpty<@Sendable (Int) -> String>>(
            NonEmpty(head: { "\($0 + 1)" }, tail: [{ "\($0 * 10)" }]),
            ["fns"]
        )
        let wa = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1, tail: [2]), ["vals"])
        let result = applyWriterNonEmpty(wf, wa)
        #expect(result.value == NonEmpty(head: "2", tail: ["3", "10", "20"]))
        #expect(result.log == ["fns", "vals"])
    }

    // MARK: - liftA2

    @Test func liftA2CombinesElementwise() {
        let wa = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 3, tail: [6]), ["a"])
        let wb = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 100, tail: [200]), ["b"])
        let result = liftA2WriterNonEmpty { (a: Int, b: Int) in a + b }(wa, wb)
        #expect(result.value == NonEmpty(head: 103, tail: [203, 106, 206]))
        #expect(result.log == ["a", "b"])
    }

    // MARK: - seqRight / seqLeft

    @Test func seqRightKeepsRightValue() {
        let lhs = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1), ["lhs"])
        let rhs = Writer<[String], NonEmpty<String>>(NonEmpty(head: "b"), ["rhs"])
        let result = seqRightWriterNonEmpty(lhs, rhs)
        #expect(result.value == NonEmpty(head: "b"))
        #expect(result.log == ["lhs", "rhs"])
    }

    @Test func seqLeftKeepsLeftValue() {
        let lhs = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1), ["lhs"])
        let rhs = Writer<[String], NonEmpty<String>>(NonEmpty(head: "b"), ["rhs"])
        let result = seqLeftWriterNonEmpty(lhs, rhs)
        #expect(result.value == NonEmpty(head: 1))
        #expect(result.log == ["lhs", "rhs"])
    }

    // MARK: - kleisliT

    @Test func kleisliTChainsWriterNonEmptyArrows() {
        let step1: @Sendable (Int) -> Writer<[String], NonEmpty<Int>?> = { n in
            Writer(NonEmpty(head: n + 1, tail: [n * 2]), ["step1(\(n))"])
        }
        let step2: @Sendable (Int) -> Writer<[String], NonEmpty<String>?> = { n in
            Writer(NonEmpty(head: "\(n)"), ["step2(\(n))"])
        }
        let pipeline = kleisliT(step1, step2)
        let result = pipeline(3)
        #expect(result.value == NonEmpty(head: "4", tail: ["6"]))
        #expect(result.log == ["step1(3)", "step2(4)", "step2(6)"])
    }

    @Test func kleisliTShortCircuitsWhenFirstIsNil() {
        let step1: @Sendable (Int) -> Writer<[String], NonEmpty<Int>?> = const(Writer(nil, ["empty"]))
        let step2: @Sendable (Int) -> Writer<[String], NonEmpty<String>?> = { n in
            Writer(NonEmpty(head: "\(n)"), ["step2"])
        }
        let pipeline = kleisliT(step1, step2)
        let result = pipeline(3)
        #expect(result.value == nil)
        #expect(result.log == ["empty"])
    }
}
