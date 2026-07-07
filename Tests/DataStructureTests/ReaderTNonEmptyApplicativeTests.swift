// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct ReaderTNonEmptyApplicativeTests {
    struct Env { let factor: Int }

    // MARK: - apply

    @Test func applyCombinesFunctionsAndValues() {
        let readerF = Reader<Env, NonEmpty<@Sendable (Int) -> String>> { env in
            NonEmpty(head: { "\($0 + env.factor)" }, tail: [{ "\($0 * env.factor)" }])
        }
        let readerA = Reader<Env, NonEmpty<Int>>(const(NonEmpty(head: 1, tail: [2])))
        let result = applyReaderNonEmpty(readerF, readerA).runReader(Env(factor: 10))
        #expect(result == NonEmpty(head: "11", tail: ["12", "10", "20"]))
    }

    // MARK: - liftA2

    @Test func liftA2CombinesElementwise() {
        let readerA = Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor, tail: [env.factor * 2]) }
        let readerB = Reader<Env, NonEmpty<Int>>(const(NonEmpty(head: 100, tail: [200])))
        let result = liftA2ReaderNonEmpty { (a: Int, b: Int) in a + b }(readerA, readerB).runReader(Env(factor: 3))
        #expect(result == NonEmpty(head: 103, tail: [203, 106, 206]))
    }

    // MARK: - seqRight / seqLeft

    @Test func seqRightKeepsRightValue() {
        let lhs = Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor) }
        let rhs = Reader<Env, NonEmpty<String>>(const(NonEmpty(head: "b")))
        let result = seqRightReaderNonEmpty(lhs, rhs).runReader(Env(factor: 1))
        #expect(result == NonEmpty(head: "b"))
    }

    @Test func seqLeftKeepsLeftValue() {
        let lhs = Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor) }
        let rhs = Reader<Env, NonEmpty<String>>(const(NonEmpty(head: "b")))
        let result = seqLeftReaderNonEmpty(lhs, rhs).runReader(Env(factor: 7))
        #expect(result == NonEmpty(head: 7))
    }

    // MARK: - kleisliT

    @Test func kleisliTChainsReaderNonEmptyArrows() {
        let step1: @Sendable (Int) -> Reader<Env, NonEmpty<Int>?> = { n in
            Reader { env in NonEmpty(head: n + env.factor, tail: [n * env.factor]) }
        }
        let step2: @Sendable (Int) -> Reader<Env, NonEmpty<String>?> = { n in
            Reader(const(NonEmpty(head: "\(n)")))
        }
        let pipeline = kleisliT(step1, step2)
        let result = pipeline(3).runReader(Env(factor: 10))
        #expect(result == NonEmpty(head: "13", tail: ["30"]))
    }

    @Test func kleisliTShortCircuitsWhenFirstIsNil() {
        let step1: @Sendable (Int) -> Reader<Env, NonEmpty<Int>?> = const(Reader(const(nil)))
        let step2: @Sendable (Int) -> Reader<Env, NonEmpty<String>?> = { n in
            Reader(const(NonEmpty(head: "\(n)")))
        }
        let pipeline = kleisliT(step1, step2)
        let result = pipeline(3).runReader(Env(factor: 10))
        #expect(result == nil)
    }
}
