import CoreFP
import DataStructure
import DataStructureOperators
import Testing
import CoreFPOperators

@Suite struct ReaderTDeferredStreamOperatorsTests {
    struct Env { let value: Int }

    @Test func apply() async {
        let rf: Reader<Env, DeferredStream<@Sendable (Int) -> String>> = Reader { _ in
            DeferredStream { AsyncStream { c in c.yield { "\($0)" }; c.finish() } }
        }
        let ra: Reader<Env, DeferredStream<Int>> = Reader { env in
            DeferredStream { AsyncStream { c in c.yield(env.value); c.finish() } }
        }
        let result = rf <*> ra
        var values: [String] = []
        for await v in result(Env(value: 7)) { values.append(v) }
        #expect(values == ["7"])
    }

    @Test func seqRight() async {
        let lhs: Reader<Env, DeferredStream<Int>> = Reader { _ in
            DeferredStream { AsyncStream { c in c.yield(1); c.finish() } }
        }
        let rhs: Reader<Env, DeferredStream<String>> = Reader { _ in
            DeferredStream { AsyncStream { c in c.yield("hello"); c.finish() } }
        }
        let result = lhs *> rhs
        var values: [String] = []
        for await v in result(Env(value: 0)) { values.append(v) }
        #expect(values == ["hello"])
    }

    @Test func seqLeft() async {
        let lhs: Reader<Env, DeferredStream<Int>> = Reader { _ in
            DeferredStream { AsyncStream { c in c.yield(99); c.finish() } }
        }
        let rhs: Reader<Env, DeferredStream<String>> = Reader { _ in
            DeferredStream { AsyncStream { c in c.yield("ignored"); c.finish() } }
        }
        let result = lhs <* rhs
        var values: [Int] = []
        for await v in result(Env(value: 0)) { values.append(v) }
        #expect(values == [99])
    }
}
