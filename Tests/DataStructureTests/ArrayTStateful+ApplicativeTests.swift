// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct ArrayTStatefulApplicativeTests {
    // MARK: - [Stateful<S, A>] — Array as outer, Stateful as inner

    @Test func apply() {
        let fns: [Stateful<Int, @Sendable (Int) -> String>] = [.pure({ "\($0)" })]
        let vals: [Stateful<Int, Int>] = [.get]
        let result = applyArrayStateful(fns, vals)
        #expect(result.count == 1)
        #expect(result[0].eval(5) == "5")
    }

    @Test func applyCartesianProduct() {
        let fns: [Stateful<Int, @Sendable (Int) -> Int>] = [.pure({ $0 + 1 }), .pure({ $0 * 2 })]
        let vals: [Stateful<Int, Int>] = [.pure(3), .pure(4)]
        let result = applyArrayStateful(fns, vals)
        #expect(result.count == 4)
        #expect(result[0].eval(0) == 4)
        #expect(result[1].eval(0) == 5)
        #expect(result[2].eval(0) == 6)
        #expect(result[3].eval(0) == 8)
    }

    @Test func applyThreadsState() {
        let fns: [Stateful<Int, @Sendable (Int) -> Int>] = [
            Stateful { state in
                state += 1
                let captured = state
                return { $0 + captured }
            }
        ]
        let vals: [Stateful<Int, Int>] = [
            Stateful { state in
                state += 10
                return state
            }
        ]
        let result = applyArrayStateful(fns, vals)
        #expect(result.count == 1)
        // start=0: fn-stateful: state→1, f={$0+1}; val-stateful: state→11, val=11 → f(11)=12
        #expect(result[0].eval(0) == 12)
    }

    @Test func seqRight() {
        let lhs: [Stateful<Int, Int>] = [.pure(1), .pure(2)]
        let rhs: [Stateful<Int, String>] = [.pure("hello")]
        let result = seqRightArrayStateful(lhs, rhs)
        #expect(result.count == 2)
        #expect(result[0].eval(0) == "hello")
        #expect(result[1].eval(0) == "hello")
    }

    @Test func seqLeft() {
        let lhs: [Stateful<Int, Int>] = [.pure(99)]
        let rhs: [Stateful<Int, String>] = [.pure("ignored")]
        let result = seqLeftArrayStateful(lhs, rhs)
        #expect(result.count == 1)
        #expect(result[0].eval(0) == 99)
    }

    @Test func applyEmpty() {
        let fns: [Stateful<Int, @Sendable (Int) -> Int>] = []
        let vals: [Stateful<Int, Int>] = [.pure(5)]
        let result = applyArrayStateful(fns, vals)
        #expect(result.isEmpty)
    }
}
