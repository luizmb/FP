import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterStatefulOperatorsTests {
    @Test func writerMapTWithStatefulInner() {
        let w = Writer<[String], Stateful<Int, Int>>(Stateful { s in s }, ["x"])
        let result = { $0 * 4 } <£^> w
        #expect(result.value.eval(3) == 12)
        #expect(result.log == ["x"])
    }

    @Test func writerFlippedFmapWithStatefulInner() {
        let w = Writer<[String], Stateful<Int, Int>>(Stateful { s in s }, ["x"])
        let result = w <&^> { $0 * 4 }
        #expect(result.value.eval(3) == 12)
        #expect(result.log == ["x"])
    }

    @Test func statefulMapTWithWriterInner() {
        let s = Stateful<Int, Writer<[String], Int>> { state in Writer(state, ["y"]) }
        let result = { $0 * 2 } <£^> s
        let w = result.eval(5)
        #expect(w.value == 10)
        #expect(w.log == ["y"])
    }

    @Test func statefulFlatMapTWithWriterInner() {
        let s = Stateful<Int, Writer<[String], Int>> { state in
            let v = state
            state += 1
            return Writer(v, ["outer"])
        }
        let result = s >>- { n in Writer<[String], String>("\(n)", ["inner"]) }
        let (w, finalState) = result.runStateful(5)
        #expect(w.value == "5")
        #expect(w.log == ["outer", "inner"])
        #expect(finalState == 6)
    }

    @Test func writerFlatMapTKeepsOuterLog() {
        let w = Writer<[String], Stateful<Int, Int>>(Stateful { s in s }, ["outer"])
        let result = w >>- { n in
            Writer<[String], Stateful<Int, String>>(
                Stateful { state in
                    state += n
                    return "\(state)"
                },
                ["inner"]
            )
        }
        let (output, finalState) = result.value.runStateful(3)
        #expect(output == "6")
        #expect(finalState == 6)
        #expect(result.log == ["outer"])
    }

    @Test func statefulTWriterApply() {
        let sf = Stateful<Int, Writer<[String], (Int) -> String>> { _ in Writer({ "\($0)" }, ["fn"]) }
        let sa = Stateful<Int, Writer<[String], Int>> { _ in Writer(7, ["val"]) }
        let result = sf <*> sa
        let w = result.eval(0)
        #expect(w.value == "7")
        #expect(w.log == ["fn", "val"])
    }

    @Test func statefulTWriterSeqRight() {
        let lhs = Stateful<Int, Writer<[String], Int>> { _ in Writer(1, ["a"]) }
        let rhs = Stateful<Int, Writer<[String], String>> { _ in Writer("hello", ["b"]) }
        let result = lhs *> rhs
        let w = result.eval(0)
        #expect(w.value == "hello")
        #expect(w.log == ["a", "b"])
    }

    @Test func statefulTWriterSeqLeft() {
        let lhs = Stateful<Int, Writer<[String], Int>> { _ in Writer(99, ["a"]) }
        let rhs = Stateful<Int, Writer<[String], String>> { _ in Writer("ignored", ["b"]) }
        let result = lhs <* rhs
        let w = result.eval(0)
        #expect(w.value == 99)
        #expect(w.log == ["a", "b"])
    }

    @Test func writerTStatefulApply() {
        let wf = Writer<[String], Stateful<Int, (Int) -> String>>(
            Stateful { _ in { "\($0)" } },
            ["fn"]
        )
        let wa = Writer<[String], Stateful<Int, Int>>(Stateful { s in s }, ["val"])
        let result = wf <*> wa
        #expect(result.value.eval(7) == "7")
        #expect(result.log == ["fn", "val"])
    }

    @Test func writerTStatefulSeqRight() {
        let lhs = Writer<[String], Stateful<Int, Int>>(Stateful { s in s }, ["a"])
        let rhs = Writer<[String], Stateful<Int, String>>(Stateful { _ in "done" }, ["b"])
        let result = lhs *> rhs
        #expect(result.value.eval(0) == "done")
        #expect(result.log == ["a", "b"])
    }

    @Test func writerTStatefulSeqLeft() {
        let lhs = Writer<[String], Stateful<Int, Int>>(Stateful { _ in 42 }, ["a"])
        let rhs = Writer<[String], Stateful<Int, String>>(Stateful { _ in "ignored" }, ["b"])
        let result = lhs <* rhs
        #expect(result.value.eval(0) == 42)
        #expect(result.log == ["a", "b"])
    }
}
