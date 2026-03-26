import DataStructure
import Testing
import CoreFP

@Suite struct StatefulTNonEmptyTests {

    // MARK: - Stateful<S, NonEmpty<A>> — mapT (functor)

    @Test func mapT() {
        let s = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 1, tail: [2, 3]))
        let mapped = s.mapT { $0 * 2 }
        #expect(mapped.eval(0) == NonEmpty(head: 2, tail: [4, 6]))
    }

    @Test func fmapT_curried() {
        let s = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 5))
        let mapped = Stateful<Int, NonEmpty<Int>>.fmapT({ $0 + 1 })(s)
        #expect(mapped.eval(0) == NonEmpty(head: 6))
    }

    // MARK: - Stateful<S, NonEmpty<A>> — flatMapT (monad)

    @Test func flatMapT_collects_results() {
        let s = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 1, tail: [2, 3]))
        let result = s.flatMapT { n -> Stateful<Int, NonEmpty<Int>?> in
            Stateful<Int, NonEmpty<Int>?> { state in
                state += n
                return NonEmpty(head: n * 10)
            }
        }
        var state = 0
        let value = result.run(&state)
        #expect(value == NonEmpty(head: 10, tail: [20, 30]))
        #expect(state == 6) // 1 + 2 + 3
    }

    @Test func flatMapT_nil_results_excluded() {
        let s = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 1, tail: [2, 3]))
        let result = s.flatMapT { n -> Stateful<Int, NonEmpty<Int>?> in
            .pure(n == 2 ? nil : NonEmpty(head: n * 10))
        }
        #expect(result.eval(0) == NonEmpty(head: 10, tail: [30]))
    }

    @Test func flatMapT_all_nil_returns_nil() {
        let s = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 1))
        let result = s.flatMapT { _ -> Stateful<Int, NonEmpty<Int>?> in .pure(nil) }
        #expect(result.eval(0) == nil)
    }

    @Test func bindT_curried() {
        let s = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 3))
        let bound = Stateful<Int, NonEmpty<Int>>.bindT({ n -> Stateful<Int, NonEmpty<Int>?> in
            .pure(NonEmpty(head: n + 1))
        })(s)
        #expect(bound.eval(0) == NonEmpty(head: 4))
    }
}
