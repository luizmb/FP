import DataStructure
import Testing
import CoreFP

@Suite struct ReaderTDeferredStreamApplicativeTests {

    struct Env { let value: Int }

    // MARK: - Reader<Env, DeferredStream<A>> — Reader as outer, DeferredStream as inner

    @Test func apply() async {
        let rf: Reader<Env, DeferredStream<@Sendable (Int) -> String>> = Reader { _ in
            DeferredStream { AsyncStream { c in c.yield { "\($0)" }; c.finish() } }
        }
        let ra: Reader<Env, DeferredStream<Int>> = Reader { env in
            DeferredStream { AsyncStream { c in c.yield(env.value); c.finish() } }
        }
        let result = applyReaderDeferredStream(rf, ra)
        var values: [String] = []
        for await v in result(Env(value: 7)) { values.append(v) }
        #expect(values == ["7"])
    }

    @Test func applyUsesEnv() async {
        let rf: Reader<Env, DeferredStream<@Sendable (Int) -> Int>> = Reader { env in
            let mul = env.value
            return DeferredStream { AsyncStream { c in c.yield { $0 + mul }; c.finish() } }
        }
        let ra: Reader<Env, DeferredStream<Int>> = Reader { env in
            DeferredStream { AsyncStream { c in c.yield(env.value * 2); c.finish() } }
        }
        let result = applyReaderDeferredStream(rf, ra)
        let env = Env(value: 5)
        var values: [Int] = []
        for await v in result(env) { values.append(v) }
        #expect(values == [15])
    }

    @Test func seqRight() async {
        let lhs: Reader<Env, DeferredStream<Int>> = Reader { _ in
            DeferredStream { AsyncStream { c in c.yield(1); c.finish() } }
        }
        let rhs: Reader<Env, DeferredStream<String>> = Reader { _ in
            DeferredStream { AsyncStream { c in c.yield("hello"); c.finish() } }
        }
        let result = seqRightReaderDeferredStream(lhs, rhs)
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
        let result = seqLeftReaderDeferredStream(lhs, rhs)
        var values: [Int] = []
        for await v in result(Env(value: 0)) { values.append(v) }
        #expect(values == [99])
    }
}
