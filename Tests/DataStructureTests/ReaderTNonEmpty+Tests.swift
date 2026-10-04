// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct ReaderTNonEmptyTests {
    struct Env { let factor: Int }

    // MARK: - Reader<Env, NonEmpty<A>> — mapT (functor)

    @Test func mapT() {
        let reader = Reader<Env, NonEmpty<Int>> { env in
            NonEmpty(head: env.factor, tail: [env.factor * 2])
        }
        let mapped = reader.mapT { $0 + 1 }
        let env = Env(factor: 3)
        #expect(mapped.runReader(env) == NonEmpty(head: 4, tail: [7]))
    }

    @Test func fmapT_curried() {
        let reader = Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor) }
        let mapped = Reader<Env, NonEmpty<Int>>.fmapT { $0 * 2 }(reader)
        #expect(mapped.runReader(Env(factor: 5)) == NonEmpty(head: 10))
    }

    // MARK: - Reader<Env, NonEmpty<A>> — flatMapT (monad)

    @Test func flatMapT_collects_results() {
        let reader = Reader<Env, NonEmpty<Int>>(const(NonEmpty(head: 1, tail: [2, 3])))
        let result = reader.flatMapT { n -> Reader<Env, NonEmpty<Int>> in
            Reader { env in NonEmpty(head: n * env.factor) }
        }
        let env = Env(factor: 10)
        #expect(result.runReader(env) == NonEmpty(head: 10, tail: [20, 30]))
    }

    @Test func flatMapT_concatenates_in_order() {
        let reader = Reader<Env, NonEmpty<Int>>(const(NonEmpty(head: 1, tail: [2])))
        let result = reader.flatMapT { n -> Reader<Env, NonEmpty<Int>> in
            Reader { env in NonEmpty(head: n, tail: [n * env.factor]) }
        }
        #expect(result.runReader(Env(factor: 10)) == NonEmpty(head: 1, tail: [10, 2, 20]))
    }

    @Test func bindT_curried() {
        let reader = Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor) }
        let bound = Reader<Env, NonEmpty<Int>>.bindT { n -> Reader<Env, NonEmpty<Int>> in
            Reader(const(NonEmpty(head: n + 1)))
        }(reader)
        #expect(bound.runReader(Env(factor: 4)) == NonEmpty(head: 5))
    }
}
