import DataStructureOperators
import DataStructure
import Testing
import CoreFPOperators
import CoreFP

@Suite struct WriterTDeferredTaskOperatorsTests {

    @Test func fmap() async {
        let w = Writer<[String], DeferredTask<Int>>(DeferredTask { 5 }, ["log"])
        let result = { $0 * 2 } <£^> w
        let value = await result.value.run()
        #expect(value == 10)
        #expect(result.log == ["log"])
    }

    @Test func flippedFmap() async {
        let w = Writer<[String], DeferredTask<Int>>(DeferredTask { 5 }, ["log"])
        let result = w <&^> { $0 * 2 }
        let value = await result.value.run()
        #expect(value == 10)
        #expect(result.log == ["log"])
    }

    @Test func bind() async {
        let w = Writer<[String], DeferredTask<Int>>(DeferredTask { 3 }, ["outer"])
        let result = w >>- { n in
            Writer<[String], DeferredTask<String>>(DeferredTask { "\(n)" }, ["inner"])
        }
        let value = await result.value.run()
        #expect(value == "3")
        #expect(result.log == ["outer"])
    }

    @Test func kleisli() async {
        let f: @Sendable (Int) -> Writer<[String], DeferredTask<Int>> = { n in Writer(DeferredTask { n + 1 }, ["f"]) }
        let g: @Sendable (Int) -> Writer<[String], DeferredTask<String>> = { n in Writer(DeferredTask { "\(n)" }, ["g"]) }
        let result = (f >=> g)(4)
        let value = await result.value.run()
        #expect(value == "5")
        #expect(result.log == ["f"])
    }

    @Test func apply() async {
        let wf = Writer<[String], DeferredTask<@Sendable (Int) -> String>>(
            DeferredTask { { "\($0)" } },
            ["fn"]
        )
        let wa = Writer<[String], DeferredTask<Int>>(DeferredTask { 42 }, ["val"])
        let result = wf <*> wa
        let value = await result.value.run()
        #expect(value == "42")
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() async {
        let lhs = Writer<[String], DeferredTask<Int>>(DeferredTask { 1 }, ["a"])
        let rhs = Writer<[String], DeferredTask<String>>(DeferredTask { "hello" }, ["b"])
        let result = lhs *> rhs
        let value = await result.value.run()
        #expect(value == "hello")
        #expect(result.log == ["a", "b"])
    }

    @Test func seqLeft() async {
        let lhs = Writer<[String], DeferredTask<Int>>(DeferredTask { 99 }, ["a"])
        let rhs = Writer<[String], DeferredTask<String>>(DeferredTask { "ignored" }, ["b"])
        let result = lhs <* rhs
        let value = await result.value.run()
        #expect(value == 99)
        #expect(result.log == ["a", "b"])
    }
}
