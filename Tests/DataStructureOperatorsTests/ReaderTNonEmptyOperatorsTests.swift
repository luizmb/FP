// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ReaderTNonEmptyOperatorsTests {
    struct Env { let factor: Int }

    // MARK: - Applicative operators

    @Test func applyOperator() {
        let readerF = Reader<Env, NonEmpty<@Sendable (Int) -> Int>> { env in NonEmpty(head: { $0 + env.factor }) }
        let readerA = Reader<Env, NonEmpty<Int>>(const(NonEmpty(head: 1, tail: [2])))
        let result = (readerF.readerT <*> readerA.readerT).rawValue
        #expect(result.runReader(Env(factor: 10)) == NonEmpty(head: 11, tail: [12]))
    }

    @Test func seqRightOperator() {
        let lhs = Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor) }
        let rhs = Reader<Env, NonEmpty<String>>(const(NonEmpty(head: "b")))
        let result = (lhs.readerT *> rhs.readerT).rawValue
        #expect(result.runReader(Env(factor: 1)) == NonEmpty(head: "b"))
    }

    @Test func seqLeftOperator() {
        let lhs = Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor) }
        let rhs = Reader<Env, NonEmpty<String>>(const(NonEmpty(head: "b")))
        let result = (lhs.readerT <* rhs.readerT).rawValue
        #expect(result.runReader(Env(factor: 7)) == NonEmpty(head: 7))
    }

    // MARK: - Monad operators

    @Test func bindOperator_forward() {
        let reader = Reader<Env, NonEmpty<Int>>(const(NonEmpty(head: 1, tail: [2])))
        let next: @Sendable (Int) -> ReaderTNonEmpty<Env, Int> = { n in Reader { env in NonEmpty(head: n * env.factor) }.readerT }
        let result = (reader.readerT >>- next).rawValue
        #expect(result.runReader(Env(factor: 10)) == NonEmpty(head: 10, tail: [20]))
    }

    @Test func bindOperator_flipped() {
        let reader = Reader<Env, NonEmpty<Int>>(const(NonEmpty(head: 1, tail: [2])))
        let fn: @Sendable (Int) -> Reader<Env, NonEmpty<Int>> = { n in Reader { env in NonEmpty(head: n * env.factor) } }
        let result = ({ fn($0).readerT } -<< reader.readerT).rawValue
        #expect(result.runReader(Env(factor: 10)) == NonEmpty(head: 10, tail: [20]))
    }

    @Test func kleisliOperator_forward() {
        let step1: @Sendable (Int) -> Reader<Env, NonEmpty<Int>> = { n in Reader { env in NonEmpty(head: n + env.factor, tail: [n]) } }
        let step2: @Sendable (Int) -> Reader<Env, NonEmpty<String>> = { n in
            Reader { env in NonEmpty(head: "\(n)", tail: ["\(env.factor)"]) }
        }
        let pipeline = { step1($0).readerT } >=> { step2($0).readerT }
        #expect(pipeline(3).rawValue.runReader(Env(factor: 10)) == NonEmpty(head: "13", tail: ["10", "3", "10"]))
    }

    @Test func kleisliOperator_reverse() {
        let step1: @Sendable (Int) -> Reader<Env, NonEmpty<Int>> = { n in Reader { env in NonEmpty(head: n + env.factor, tail: [n]) } }
        let step2: @Sendable (Int) -> Reader<Env, NonEmpty<String>> = { n in
            Reader { env in NonEmpty(head: "\(n)", tail: ["\(env.factor)"]) }
        }
        let pipeline = { step2($0).readerT } <=< { step1($0).readerT }
        #expect(pipeline(3).rawValue.runReader(Env(factor: 10)) == NonEmpty(head: "13", tail: ["10", "3", "10"]))
    }
}
