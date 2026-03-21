import Testing
import WriterStatefulOperators
import WriterStateful
import WriterOperators
import StatefulOperators
import Writer
import Stateful
import FP

@Suite struct WriterStatefulOperatorsTests {

    @Test func writerMapTWithStatefulInner() {
        let w = Writer<[String], Stateful<Int, Int>>(Stateful { s in s }, ["x"])
        let result = w.mapT { $0 * 4 }
        #expect(result.value.eval(3) == 12)
        #expect(result.log == ["x"])
    }

    @Test func statefulMapTWithWriterInner() {
        let s = Stateful<Int, Writer<[String], Int>> { state in Writer(state, ["y"]) }
        let result = s.mapT { $0 * 2 }
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
        let result = s.flatMapT { n in Writer<[String], String>("\(n)", ["inner"]) }
        let (w, finalState) = result.runStateful(5)
        #expect(w.value == "5")
        #expect(w.log == ["outer", "inner"])
        #expect(finalState == 6)
    }

    @Test func writerFlatMapTKeepsOuterLog() {
        let w = Writer<[String], Stateful<Int, Int>>(Stateful { s in s }, ["outer"])
        let result = w.flatMapT { n in
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
}
