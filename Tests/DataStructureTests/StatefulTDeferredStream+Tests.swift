import CoreFP
import DataStructure
import Testing

@Suite struct StatefulTDeferredStreamTests {
    // MARK: - Stateful<S, DeferredStream<A>> — State as outer, DeferredStream as inner
    // Note: flatMapT is not implementable for this stack.

    @Test func mapTTransformsValues() async {
        let s = Stateful<Int, DeferredStream<Int>> { _ in
            DeferredStream { AsyncStream { c in
                c.yield(1)
                c.yield(2)
                c.yield(3)
                c.finish()
            }
            }
        }
        let mapped = s.mapT { $0 * 10 }
        var results: [Int] = []
        for await value in mapped.eval(0) {
            results.append(value)
        }
        #expect(results == [10, 20, 30])
    }

    @Test func mapTPreservesState() async {
        let s = Stateful<Int, DeferredStream<Int>> { state in
            let v = state
            state += 1
            return DeferredStream { AsyncStream { c in
                c.yield(v)
                c.finish()
            }
            }
        }
        let mapped = s.mapT { $0 + 100 }
        let (stream, finalState) = mapped.runStateful(7)
        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }
        #expect(results == [107])
        #expect(finalState == 8)
    }

    @Test func applicativeZipsElements() async {
        let sf = Stateful<Int, DeferredStream<@Sendable (Int) -> String>> { _ in
            DeferredStream { AsyncStream { c in
                c.yield { "\($0)" }
                c.finish()
            }
            }
        }
        let sa = Stateful<Int, DeferredStream<Int>> { _ in
            DeferredStream { AsyncStream { c in
                c.yield(42)
                c.finish()
            }
            }
        }
        let result = applyStatefulDeferredStream(sf, sa)
        var results: [String] = []
        for await value in result.eval(0) { results.append(value) }
        #expect(results == ["42"])
    }

    @Test func seqRight() async {
        let lhs = Stateful<Int, DeferredStream<Int>> { _ in
            DeferredStream { AsyncStream { c in c.yield(1); c.finish() } }
        }
        let rhs = Stateful<Int, DeferredStream<String>> { _ in
            DeferredStream { AsyncStream { c in c.yield("hello"); c.finish() } }
        }
        let result = seqRightStatefulDeferredStream(lhs, rhs)
        var results: [String] = []
        for await value in result.eval(0) { results.append(value) }
        #expect(results == ["hello"])
    }

    @Test func seqLeft() async {
        let lhs = Stateful<Int, DeferredStream<Int>> { _ in
            DeferredStream { AsyncStream { c in c.yield(99); c.finish() } }
        }
        let rhs = Stateful<Int, DeferredStream<String>> { _ in
            DeferredStream { AsyncStream { c in c.yield("ignored"); c.finish() } }
        }
        let result = seqLeftStatefulDeferredStream(lhs, rhs)
        var results: [Int] = []
        for await value in result.eval(0) { results.append(value) }
        #expect(results == [99])
    }
}
