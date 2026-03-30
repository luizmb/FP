import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ReaderTDeferredTaskOperatorsTests {
    struct Env { let value: Int }

    @Test func apply() async {
        let rf: Reader<Env, DeferredTask<@Sendable (Int) -> String>> = Reader { _ in DeferredTask { { "\($0)" } } }
        let ra: Reader<Env, DeferredTask<Int>> = Reader { env in DeferredTask { env.value } }
        let result = rf <*> ra
        let value = await result(Env(value: 42)).run()
        #expect(value == "42")
    }

    @Test func seqRight() async {
        let lhs: Reader<Env, DeferredTask<Int>> = Reader { _ in DeferredTask { 1 } }
        let rhs: Reader<Env, DeferredTask<String>> = Reader { _ in DeferredTask { "hello" } }
        let result = lhs *> rhs
        let value = await result(Env(value: 0)).run()
        #expect(value == "hello")
    }

    @Test func seqLeft() async {
        let lhs: Reader<Env, DeferredTask<Int>> = Reader { _ in DeferredTask { 99 } }
        let rhs: Reader<Env, DeferredTask<String>> = Reader { _ in DeferredTask { "ignored" } }
        let result = lhs <* rhs
        let value = await result(Env(value: 0)).run()
        #expect(value == 99)
    }
}
