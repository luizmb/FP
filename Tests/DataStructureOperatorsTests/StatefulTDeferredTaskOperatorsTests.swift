import DataStructureOperators
import DataStructure
import Testing
import CoreFPOperators
import CoreFP

@Suite struct StatefulTDeferredTaskOperatorsTests {

    @Test func fmap() async {
        let s = Stateful<Int, DeferredTask<Int>> { _ in DeferredTask { 5 } }
        let result = { $0 * 2 } <£^> s
        let value = await result.eval(0).run()
        #expect(value == 10)
    }

    @Test func fmapPreservesState() async {
        let s = Stateful<Int, DeferredTask<Int>> { _ in DeferredTask { 3 } }
        let result = { $0 + 1 } <£^> s
        let value = await result.eval(0).run()
        #expect(value == 4)
    }

    @Test func apply() async {
        let sf = Stateful<Int, DeferredTask<@Sendable (Int) -> String>> { _ in DeferredTask { { "\($0)" } } }
        let sa = Stateful<Int, DeferredTask<Int>> { _ in DeferredTask { 42 } }
        let result = sf <*> sa
        let value = await result.eval(0).run()
        #expect(value == "42")
    }

    @Test func seqRight() async {
        let lhs = Stateful<Int, DeferredTask<Int>> { _ in DeferredTask { 1 } }
        let rhs = Stateful<Int, DeferredTask<String>> { _ in DeferredTask { "hello" } }
        let result = lhs *> rhs
        let value = await result.eval(0).run()
        #expect(value == "hello")
    }

    @Test func seqLeft() async {
        let lhs = Stateful<Int, DeferredTask<Int>> { _ in DeferredTask { 99 } }
        let rhs = Stateful<Int, DeferredTask<String>> { _ in DeferredTask { "ignored" } }
        let result = lhs <* rhs
        let value = await result.eval(0).run()
        #expect(value == 99)
    }
}
