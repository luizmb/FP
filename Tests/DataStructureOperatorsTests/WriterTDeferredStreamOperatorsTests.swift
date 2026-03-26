import DataStructureOperators
import DataStructure
import Testing
import CoreFPOperators
import CoreFP

@Suite struct WriterTDeferredStreamOperatorsTests {

    @Test func fmap() async {
        let stream = DeferredStream<Int> { AsyncStream { c in
            c.yield(1)
            c.yield(2)
            c.finish()
        } }
        let w = Writer<[String], DeferredStream<Int>>(stream, ["log"])
        let result = { $0 * 3 } <£^> w
        var values: [Int] = []
        for await v in result.value {
            values.append(v)
        }
        #expect(values == [3, 6])
        #expect(result.log == ["log"])
    }

    @Test func flippedFmap() async {
        let stream = DeferredStream<Int> { AsyncStream { c in
            c.yield(1)
            c.yield(2)
            c.finish()
        } }
        let w = Writer<[String], DeferredStream<Int>>(stream, ["log"])
        let result = w <&^> { $0 * 3 }
        var values: [Int] = []
        for await v in result.value {
            values.append(v)
        }
        #expect(values == [3, 6])
        #expect(result.log == ["log"])
    }

    @Test func bind() async {
        let stream = DeferredStream<Int> { AsyncStream { c in
            c.yield(4)
            c.finish()
        } }
        let w = Writer<[String], DeferredStream<Int>>(stream, ["outer"])
        let result = w >>- { n in
            Writer<[String], DeferredStream<String>>(
                DeferredStream { AsyncStream { c in
                    c.yield("\(n * 2)")
                    c.finish()
                } },
                ["inner"]
            )
        }
        var values: [String] = []
        for await v in result.value {
            values.append(v)
        }
        #expect(values == ["8"])
        #expect(result.log == ["outer"])
    }

    @Test func apply() async {
        let wf = Writer<[String], DeferredStream<@Sendable (Int) -> String>>(
            DeferredStream { AsyncStream { c in c.yield { "\($0)" }; c.finish() } },
            ["fn"]
        )
        let wa = Writer<[String], DeferredStream<Int>>(
            DeferredStream { AsyncStream { c in c.yield(7); c.finish() } },
            ["val"]
        )
        let result = wf <*> wa
        var values: [String] = []
        for await v in result.value { values.append(v) }
        #expect(values == ["7"])
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() async {
        let lhs = Writer<[String], DeferredStream<Int>>(
            DeferredStream { AsyncStream { c in c.yield(1); c.finish() } },
            ["a"]
        )
        let rhs = Writer<[String], DeferredStream<String>>(
            DeferredStream { AsyncStream { c in c.yield("hello"); c.finish() } },
            ["b"]
        )
        let result = lhs *> rhs
        var values: [String] = []
        for await v in result.value { values.append(v) }
        #expect(values == ["hello"])
        #expect(result.log == ["a", "b"])
    }

    @Test func seqLeft() async {
        let lhs = Writer<[String], DeferredStream<Int>>(
            DeferredStream { AsyncStream { c in c.yield(99); c.finish() } },
            ["a"]
        )
        let rhs = Writer<[String], DeferredStream<String>>(
            DeferredStream { AsyncStream { c in c.yield("ignored"); c.finish() } },
            ["b"]
        )
        let result = lhs <* rhs
        var values: [Int] = []
        for await v in result.value { values.append(v) }
        #expect(values == [99])
        #expect(result.log == ["a", "b"])
    }
}
