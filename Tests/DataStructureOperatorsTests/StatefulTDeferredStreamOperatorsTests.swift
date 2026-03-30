import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct StatefulTDeferredStreamOperatorsTests {
    @Test func fmap() async {
        let s = Stateful<Int, DeferredStream<Int>> { _ in
            DeferredStream { AsyncStream { c in
                c.yield(1)
                c.yield(2)
                c.finish()
            }
            }
        }
        let result = { $0 * 10 } <£^> s
        var values: [Int] = []
        for await v in result.eval(0) {
            values.append(v)
        }
        #expect(values == [10, 20])
    }

    @Test func flippedFmap() async {
        let s = Stateful<Int, DeferredStream<Int>> { _ in
            DeferredStream { AsyncStream { c in
                c.yield(1)
                c.yield(2)
                c.finish()
            }
            }
        }
        let result = s <&^> { $0 * 10 }
        var values: [Int] = []
        for await v in result.eval(0) {
            values.append(v)
        }
        #expect(values == [10, 20])
    }

    @Test func fmapTransformsSingleValue() async {
        let s = Stateful<Int, DeferredStream<Int>> { _ in
            DeferredStream { AsyncStream { c in
                c.yield(5)
                c.finish()
            }
            }
        }
        let result = { $0 + 100 } <£^> s
        var values: [Int] = []
        for await v in result.eval(0) {
            values.append(v)
        }
        #expect(values == [105])
    }

    @Test func apply() async {
        let sf = Stateful<Int, DeferredStream<@Sendable (Int) -> String>> { _ in
            DeferredStream { AsyncStream { c in c.yield { "\($0)" }; c.finish() } }
        }
        let sa = Stateful<Int, DeferredStream<Int>> { _ in
            DeferredStream { AsyncStream { c in c.yield(42); c.finish() } }
        }
        let result = sf <*> sa
        var values: [String] = []
        for await v in result.eval(0) { values.append(v) }
        #expect(values == ["42"])
    }

    @Test func seqRight() async {
        let lhs = Stateful<Int, DeferredStream<Int>> { _ in
            DeferredStream { AsyncStream { c in c.yield(1); c.finish() } }
        }
        let rhs = Stateful<Int, DeferredStream<String>> { _ in
            DeferredStream { AsyncStream { c in c.yield("hello"); c.finish() } }
        }
        let result = lhs *> rhs
        var values: [String] = []
        for await v in result.eval(0) { values.append(v) }
        #expect(values == ["hello"])
    }

    @Test func seqLeft() async {
        let lhs = Stateful<Int, DeferredStream<Int>> { _ in
            DeferredStream { AsyncStream { c in c.yield(99); c.finish() } }
        }
        let rhs = Stateful<Int, DeferredStream<String>> { _ in
            DeferredStream { AsyncStream { c in c.yield("ignored"); c.finish() } }
        }
        let result = lhs <* rhs
        var values: [Int] = []
        for await v in result.eval(0) { values.append(v) }
        #expect(values == [99])
    }
}
