import CoreFP
import DataStructure
import Testing

@Suite struct StatefulTDeferredTaskTests {
    // MARK: - Stateful<S, DeferredTask<A>> — State as outer, DeferredTask as inner
    // Note: flatMapT is not implementable for this stack.

    @Test func mapTTransformsValue() async {
        let s = Stateful<Int, DeferredTask<Int>> { _ in DeferredTask { 5 } }
        let mapped = s.mapT { $0 * 2 }
        let result = await mapped.eval(0).run()
        #expect(result == 10)
    }

    @Test func mapTPreservesState() async {
        let s = Stateful<Int, DeferredTask<Int>> { state in
            let v = state
            state += 1
            return DeferredTask { v }
        }
        let mapped = s.mapT { $0 + 100 }
        let (task, finalState) = mapped.runStateful(3)
        let result = await task.run()
        #expect(result == 103)
        #expect(finalState == 4)
    }

    @Test func mapTIdentity() async {
        let s = Stateful<Int, DeferredTask<String>> { _ in DeferredTask { "hello" } }
        let mapped = s.mapT { $0 }
        let result = await mapped.eval(0).run()
        #expect(result == "hello")
    }

    @Test func applicativeThreadsState() async {
        let sf = Stateful<Int, DeferredTask<@Sendable (Int) -> String>> { state in
            state += 1
            return DeferredTask { { "\($0)" } }
        }
        let sa = Stateful<Int, DeferredTask<Int>> { state in
            state += 10
            let captured = state
            return DeferredTask { captured }
        }
        let result = applyStatefulDeferredTask(sf, sa)
        var s = 0
        let task = result.run(&s)
        let value = await task.run()
        #expect(value == "11")
        #expect(s == 11)
    }

    @Test func seqRight() async {
        let lhs = Stateful<Int, DeferredTask<Int>> { _ in DeferredTask { 1 } }
        let rhs = Stateful<Int, DeferredTask<String>> { _ in DeferredTask { "hello" } }
        let result = seqRightStatefulDeferredTask(lhs, rhs)
        let value = await result.eval(0).run()
        #expect(value == "hello")
    }

    @Test func seqLeft() async {
        let lhs = Stateful<Int, DeferredTask<Int>> { _ in DeferredTask { 99 } }
        let rhs = Stateful<Int, DeferredTask<String>> { _ in DeferredTask { "ignored" } }
        let result = seqLeftStatefulDeferredTask(lhs, rhs)
        let value = await result.eval(0).run()
        #expect(value == 99)
    }
}
