import DataStructure
import Testing
import CoreFP

@Suite struct WriterTDeferredTaskTests {

    // MARK: - Writer<W, DeferredTask<A>> — Writer as outer, DeferredTask as inner

    @Test func mapT() async {
        let w = Writer<[String], DeferredTask<Int>>(DeferredTask { 5 }, ["log"])
        let mapped = w.mapT { $0 * 2 }
        let result = await mapped.value.run()
        #expect(result == 10)
        #expect(mapped.log == ["log"])
    }

    @Test func flatMapTPreservesOuterLog() async {
        let w = Writer<[String], DeferredTask<Int>>(DeferredTask { 3 }, ["outer"])
        let result = w.flatMapT { n in
            Writer<[String], DeferredTask<String>>(DeferredTask { "\(n * 2)" }, ["inner"])
        }
        let value = await result.value.run()
        #expect(value == "6")
        #expect(result.log == ["outer"])
    }

    @Test func flatMapTChains() async {
        let w = Writer<[String], DeferredTask<Int>>(DeferredTask { 10 }, ["a"])
        let step2: @Sendable (Int) -> Writer<[String], DeferredTask<Int>> = { n in
            Writer(DeferredTask { n + 5 }, ["b"])
        }
        let result = w.flatMapT(step2)
        let value = await result.value.run()
        #expect(value == 15)
        #expect(result.log == ["a"])
    }

    @Test func applicativeLogsAccumulate() async {
        let wf = Writer<[String], DeferredTask<@Sendable (Int) -> String>>(
            DeferredTask { { "\($0)" } },
            ["fn"]
        )
        let wa = Writer<[String], DeferredTask<Int>>(DeferredTask { 42 }, ["val"])
        let result = applyWriterDeferredTask(wf, wa)
        let value = await result.value.run()
        #expect(value == "42")
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() async {
        let lhs = Writer<[String], DeferredTask<Int>>(DeferredTask { 1 }, ["a"])
        let rhs = Writer<[String], DeferredTask<String>>(DeferredTask { "hello" }, ["b"])
        let result = seqRightWriterDeferredTask(lhs, rhs)
        let value = await result.value.run()
        #expect(value == "hello")
        #expect(result.log == ["a", "b"])
    }

    @Test func seqLeft() async {
        let lhs = Writer<[String], DeferredTask<Int>>(DeferredTask { 99 }, ["a"])
        let rhs = Writer<[String], DeferredTask<String>>(DeferredTask { "ignored" }, ["b"])
        let result = seqLeftWriterDeferredTask(lhs, rhs)
        let value = await result.value.run()
        #expect(value == 99)
        #expect(result.log == ["a", "b"])
    }
}
