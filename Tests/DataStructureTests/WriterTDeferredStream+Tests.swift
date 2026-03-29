import CoreFP
import DataStructure
import Testing

@Suite struct WriterTDeferredStreamTests {
    // MARK: - Writer<W, DeferredStream<A>> — Writer as outer, DeferredStream as inner

    @Test func mapT() async {
        let stream = DeferredStream<Int> { AsyncStream { c in
            c.yield(1)
            c.yield(2)
            c.finish()
        }
        }
        let w = Writer<[String], DeferredStream<Int>>(stream, ["log"])
        let mapped = w.mapT { $0 * 3 }
        var results: [Int] = []
        for await value in mapped.value {
            results.append(value)
        }
        #expect(results == [3, 6])
        #expect(mapped.log == ["log"])
    }

    @Test func flatMapTPreservesOuterLog() async {
        let stream = DeferredStream<Int> { AsyncStream { c in
            c.yield(5)
            c.finish()
        }
        }
        let w = Writer<[String], DeferredStream<Int>>(stream, ["outer"])
        let result = w.flatMapT { n in
            Writer<[String], DeferredStream<String>>(
                DeferredStream { AsyncStream { c in
                    c.yield("\(n)")
                    c.finish()
                }
                },
                ["inner"]
            )
        }
        var results: [String] = []
        for await value in result.value {
            results.append(value)
        }
        #expect(results == ["5"])
        #expect(result.log == ["outer"])
    }

    @Test func applicativeLogsAccumulate() async {
        let wf = Writer<[String], DeferredStream<@Sendable (Int) -> String>>(
            DeferredStream { AsyncStream { c in
                c.yield { "\($0)" }
                c.finish()
            }
            },
            ["fn"]
        )
        let wa = Writer<[String], DeferredStream<Int>>(
            DeferredStream { AsyncStream { c in
                c.yield(7)
                c.finish()
            }
            },
            ["val"]
        )
        let result = applyWriterDeferredStream(wf, wa)
        var results: [String] = []
        for await value in result.value {
            results.append(value)
        }
        #expect(results == ["7"])
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
        let result = seqRightWriterDeferredStream(lhs, rhs)
        var results: [String] = []
        for await value in result.value { results.append(value) }
        #expect(results == ["hello"])
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
        let result = seqLeftWriterDeferredStream(lhs, rhs)
        var results: [Int] = []
        for await value in result.value { results.append(value) }
        #expect(results == [99])
        #expect(result.log == ["a", "b"])
    }
}
