import DataStructure
import Testing
import Core

@Suite struct WriterStatefulTests {

    // MARK: - Writer<W, Stateful<S, A>> — Writer as outer, Stateful as inner

    @Test func mapT() {
        let w = Writer<[String], Stateful<Int, Int>>(
            Stateful { s in s },
            ["log"]
        )
        let mapped = w.mapT { $0 * 2 }
        #expect(mapped.value.eval(5) == 10)
        #expect(mapped.log == ["log"])
    }

    @Test func applicativeLogsAccumulate() {
        let wf = Writer<[String], Stateful<Int, (Int) -> String>>(
            Stateful { _ in { "\($0)" } },
            ["fn"]
        )
        let wa = Writer<[String], Stateful<Int, Int>>(
            Stateful { s in s },
            ["val"]
        )
        let result = applyWriterStateful(wf, wa)
        #expect(result.value.eval(7) == "7")
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRightWriterStatefulLogsAccumulate() {
        let lhs = Writer<[String], Stateful<Int, Int>>(Stateful { s in s }, ["a"])
        let rhs = Writer<[String], Stateful<Int, String>>(Stateful { _ in "done" }, ["b"])
        let result = seqRightWriterStateful(lhs, rhs)
        #expect(result.value.eval(0) == "done")
        #expect(result.log == ["a", "b"])
    }

    @Test func flatMapTKeepsOuterLog() {
        let w = Writer<[String], Stateful<Int, Int>>(
            Stateful { s in s },
            ["outer"]
        )
        let result = w.flatMapT { n in
            Writer<[String], Stateful<Int, String>>(
                Stateful { state in
                    state += n
                    return "\(state)"
                },
                ["inner"]
            )
        }
        // inner log is discarded; state is still threaded
        let (output, finalState) = result.value.runStateful(3)
        #expect(output == "6")
        #expect(finalState == 6)
        #expect(result.log == ["outer"])
    }

    // MARK: - Stateful<S, Writer<W, A>> — Stateful as outer, Writer as inner

    @Test func statefulTWriterMapT() {
        let s = Stateful<Int, Writer<[String], Int>> { state in
            Writer(state, ["x"])
        }
        let mapped = s.mapT { $0 * 3 }
        let w = mapped.eval(4)
        #expect(w.value == 12)
        #expect(w.log == ["x"])
    }

    @Test func statefulTWriterFlatMapT() {
        let s = Stateful<Int, Writer<[String], Int>> { state in
            let v = state
            state += 1
            return Writer(v, ["outer"])
        }
        let result = s.flatMapT { n in Writer<[String], String>("\(n)", ["inner"]) }
        let (w, finalState) = result.runStateful(5)
        #expect(w.value == "5")
        #expect(w.log == ["outer", "inner"])
        #expect(finalState == 6)
    }
}
