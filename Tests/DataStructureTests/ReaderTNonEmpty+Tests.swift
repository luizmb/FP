// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct ReaderTNonEmptyTests {
    struct Env { let factor: Int }

    // MARK: - ReaderTNonEmpty — map (functor)

    @Test func map() {
        let stack = ReaderTNonEmpty(Reader<Env, NonEmpty<Int>> { env in
            NonEmpty(head: env.factor, tail: [env.factor * 2])
        })
        let mapped = stack.map { $0 + 1 }
        let env = Env(factor: 3)
        #expect(mapped.rawValue.runReader(env) == NonEmpty(head: 4, tail: [7]))
    }

    @Test func fmap_curried() {
        let stack = ReaderTNonEmpty(Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor) })
        let mapped = ReaderTNonEmpty<Env, Int>.fmap { $0 * 2 }(stack)
        #expect(mapped.rawValue.runReader(Env(factor: 5)) == NonEmpty(head: 10))
    }

    // MARK: - ReaderTNonEmpty — flatMap (monad)

    @Test func flatMap_collects_results() {
        let stack = ReaderTNonEmpty(Reader<Env, NonEmpty<Int>>(const(NonEmpty(head: 1, tail: [2, 3]))))
        let result = stack.flatMap { n -> ReaderTNonEmpty<Env, Int> in
            ReaderTNonEmpty(Reader { env in NonEmpty(head: n * env.factor) })
        }
        let env = Env(factor: 10)
        #expect(result.rawValue.runReader(env) == NonEmpty(head: 10, tail: [20, 30]))
    }

    @Test func flatMap_concatenates_in_order() {
        let stack = ReaderTNonEmpty(Reader<Env, NonEmpty<Int>>(const(NonEmpty(head: 1, tail: [2]))))
        let result = stack.flatMap { n -> ReaderTNonEmpty<Env, Int> in
            ReaderTNonEmpty(Reader { env in NonEmpty(head: n, tail: [n * env.factor]) })
        }
        #expect(result.rawValue.runReader(Env(factor: 10)) == NonEmpty(head: 1, tail: [10, 2, 20]))
    }

    @Test func bind_curried() {
        let stack = ReaderTNonEmpty(Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor) })
        let bound = ReaderTNonEmpty<Env, Int>.bind { n -> ReaderTNonEmpty<Env, Int> in
            ReaderTNonEmpty(Reader(const(NonEmpty(head: n + 1))))
        }(stack)
        #expect(bound.rawValue.runReader(Env(factor: 4)) == NonEmpty(head: 5))
    }
}
