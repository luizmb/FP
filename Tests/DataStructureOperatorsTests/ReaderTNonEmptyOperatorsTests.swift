// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ReaderTNonEmptyOperatorsTests {
    struct Env { let factor: Int }

    @Test func fmapOperator_forward() {
        let reader = Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor, tail: [env.factor * 2]) }
        let result = { $0 + 1 } <£^> reader
        #expect(result.runReader(Env(factor: 3)) == NonEmpty(head: 4, tail: [7]))
    }

    @Test func fmapOperator_flipped() {
        let reader = Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor) }
        let result = reader <&^> { $0 * 2 }
        #expect(result.runReader(Env(factor: 5)) == NonEmpty(head: 10))
    }

    // MARK: - Applicative operators

    @Test func applyOperator() {
        let readerF = Reader<Env, NonEmpty<@Sendable (Int) -> Int>> { env in NonEmpty(head: { $0 + env.factor }) }
        let readerA = Reader<Env, NonEmpty<Int>>(const(NonEmpty(head: 1, tail: [2])))
        let result = readerF <*> readerA
        #expect(result.runReader(Env(factor: 10)) == NonEmpty(head: 11, tail: [12]))
    }

    @Test func seqRightOperator() {
        let lhs = Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor) }
        let rhs = Reader<Env, NonEmpty<String>>(const(NonEmpty(head: "b")))
        let result = lhs *> rhs
        #expect(result.runReader(Env(factor: 1)) == NonEmpty(head: "b"))
    }

    @Test func seqLeftOperator() {
        let lhs = Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor) }
        let rhs = Reader<Env, NonEmpty<String>>(const(NonEmpty(head: "b")))
        let result = lhs <* rhs
        #expect(result.runReader(Env(factor: 7)) == NonEmpty(head: 7))
    }

    // MARK: - Monad operators

    @Test func bindOperator_forward() {
        let reader = Reader<Env, NonEmpty<Int>>(const(NonEmpty(head: 1, tail: [2])))
        let result = reader >>- { n -> Reader<Env, NonEmpty<Int>?> in Reader { env in NonEmpty(head: n * env.factor) } }
        #expect(result.runReader(Env(factor: 10)) == NonEmpty(head: 10, tail: [20]))
    }

    @Test func bindOperator_flipped() {
        let reader = Reader<Env, NonEmpty<Int>>(const(NonEmpty(head: 1, tail: [2])))
        let fn: @Sendable (Int) -> Reader<Env, NonEmpty<Int>?> = { n in Reader { env in NonEmpty(head: n * env.factor) } }
        let result = fn -<< reader
        #expect(result.runReader(Env(factor: 10)) == NonEmpty(head: 10, tail: [20]))
    }

    @Test func kleisliOperator_forward() {
        let step1: @Sendable (Int) -> Reader<Env, NonEmpty<Int>?> = { n in Reader { env in NonEmpty(head: n + env.factor) } }
        let step2: @Sendable (Int) -> Reader<Env, NonEmpty<String>?> = { n in Reader(const(NonEmpty(head: "\(n)"))) }
        let pipeline = step1 >=> step2
        #expect(pipeline(3).runReader(Env(factor: 10)) == NonEmpty(head: "13"))
    }

    @Test func kleisliOperator_reverse() {
        let step1: @Sendable (Int) -> Reader<Env, NonEmpty<Int>?> = { n in Reader { env in NonEmpty(head: n + env.factor) } }
        let step2: @Sendable (Int) -> Reader<Env, NonEmpty<String>?> = { n in Reader(const(NonEmpty(head: "\(n)"))) }
        let pipeline = step2 <=< step1
        #expect(pipeline(3).runReader(Env(factor: 10)) == NonEmpty(head: "13"))
    }
}
