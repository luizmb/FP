// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct ReaderTNonEmptyApplicativeTests {
    struct Env { let factor: Int }

    // MARK: - apply

    @Test func applyCombinesFunctionsAndValues() {
        let stackF = ReaderTNonEmpty(Reader<Env, NonEmpty<@Sendable (Int) -> String>> { env in
            NonEmpty(head: { "\($0 + env.factor)" }, tail: [{ "\($0 * env.factor)" }])
        })
        let stackA = ReaderTNonEmpty(Reader<Env, NonEmpty<Int>>(const(NonEmpty(head: 1, tail: [2]))))
        let result = ReaderTNonEmpty<Env, String>.apply(stackF, stackA).rawValue.runReader(Env(factor: 10))
        #expect(result == NonEmpty(head: "11", tail: ["12", "10", "20"]))
    }

    // MARK: - liftA2

    @Test func liftA2CombinesElementwise() {
        let stackA = ReaderTNonEmpty(Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor, tail: [env.factor * 2]) })
        let stackB = ReaderTNonEmpty(Reader<Env, NonEmpty<Int>>(const(NonEmpty(head: 100, tail: [200]))))
        let combine = ReaderTNonEmpty<Env, Int>.liftA2 { (a: Int, b: Int) in a + b }
        let result = combine(stackA, stackB).rawValue.runReader(Env(factor: 3))
        #expect(result == NonEmpty(head: 103, tail: [203, 106, 206]))
    }

    // MARK: - seqRight / seqLeft

    @Test func seqRightKeepsRightValue() {
        let lhs = ReaderTNonEmpty(Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor) })
        let rhs = ReaderTNonEmpty(Reader<Env, NonEmpty<String>>(const(NonEmpty(head: "b"))))
        let result = lhs.seqRight(rhs).rawValue.runReader(Env(factor: 1))
        #expect(result == NonEmpty(head: "b"))
    }

    @Test func seqLeftKeepsLeftValue() {
        let lhs = ReaderTNonEmpty(Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor) })
        let rhs = ReaderTNonEmpty(Reader<Env, NonEmpty<String>>(const(NonEmpty(head: "b"))))
        let result = lhs.seqLeft(rhs).rawValue.runReader(Env(factor: 7))
        #expect(result == NonEmpty(head: 7))
    }

    // MARK: - kleisli

    @Test func kleisliChainsReaderNonEmptyArrows() {
        let step1: @Sendable (Int) -> ReaderTNonEmpty<Env, Int> = { n in
            ReaderTNonEmpty(Reader { env in NonEmpty(head: n + env.factor, tail: [n * env.factor]) })
        }
        let step2: @Sendable (Int) -> ReaderTNonEmpty<Env, String> = { n in
            ReaderTNonEmpty(Reader(const(NonEmpty(head: "\(n)"))))
        }
        let pipeline = ReaderTNonEmpty<Env, Int>.kleisli(step1, step2)
        let result = pipeline(3).rawValue.runReader(Env(factor: 10))
        #expect(result == NonEmpty(head: "13", tail: ["30"]))
    }
}
