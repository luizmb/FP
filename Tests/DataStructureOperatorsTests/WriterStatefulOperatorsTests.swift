// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterStatefulOperatorsTests {
    @Test func statefulFlatMapTWithWriterInner() {
        let s = Stateful<Int, Writer<[String], Int>> { state in
            let v = state
            state += 1
            return Writer(v, ["outer"])
        }
        let result = s >>- { (n: Int) in
            Stateful<Int, Writer<[String], String>> { state in
                state *= 10
                return Writer("\(n)", ["inner"])
            }
        }
        let (w, finalState) = result.runStateful(5)
        #expect(w.value == "5")
        #expect(w.log == ["outer", "inner"])
        #expect(finalState == 60)
    }

    @Test func statefulTWriterApply() {
        let fn: @Sendable (Int) -> String = { "\($0)" }
        let sf = Stateful<Int, Writer<[String], @Sendable (Int) -> String>>.pure(Writer(fn, ["fn"]))
        let sa = Stateful<Int, Writer<[String], Int>>.pure(Writer(7, ["val"]))
        let result = sf <*> sa
        let w = result.eval(0)
        #expect(w.value == "7")
        #expect(w.log == ["fn", "val"])
    }

    @Test func statefulTWriterSeqRight() {
        let lhs = Stateful<Int, Writer<[String], Int>>.pure(Writer(1, ["a"]))
        let rhs = Stateful<Int, Writer<[String], String>>.pure(Writer("hello", ["b"]))
        let result = lhs *> rhs
        let w = result.eval(0)
        #expect(w.value == "hello")
        #expect(w.log == ["a", "b"])
    }

    @Test func statefulTWriterSeqLeft() {
        let lhs = Stateful<Int, Writer<[String], Int>>.pure(Writer(99, ["a"]))
        let rhs = Stateful<Int, Writer<[String], String>>.pure(Writer("ignored", ["b"]))
        let result = lhs <* rhs
        let w = result.eval(0)
        #expect(w.value == 99)
        #expect(w.log == ["a", "b"])
    }

    @Test func writerTStatefulApply() {
        let innerFn: @Sendable (Int) -> String = { "\($0)" }
        let wf = Writer<[String], Stateful<Int, @Sendable (Int) -> String>>(
            Stateful<Int, @Sendable (Int) -> String>.pure(innerFn),
            ["fn"]
        )
        let wa = Writer<[String], Stateful<Int, Int>>(Stateful<Int, Int>.get, ["val"])
        let result = wf <*> wa
        #expect(result.value.eval(7) == "7")
        #expect(result.log == ["fn", "val"])
    }

    @Test func writerTStatefulSeqRight() {
        let lhs = Writer<[String], Stateful<Int, Int>>(Stateful<Int, Int>.get, ["a"])
        let rhs = Writer<[String], Stateful<Int, String>>(Stateful<Int, String>.pure("done"), ["b"])
        let result = lhs *> rhs
        #expect(result.value.eval(0) == "done")
        #expect(result.log == ["a", "b"])
    }

    @Test func writerTStatefulSeqLeft() {
        let lhs = Writer<[String], Stateful<Int, Int>>(Stateful<Int, Int>.pure(42), ["a"])
        let rhs = Writer<[String], Stateful<Int, String>>(Stateful<Int, String>.pure("ignored"), ["b"])
        let result = lhs <* rhs
        #expect(result.value.eval(0) == 42)
        #expect(result.log == ["a", "b"])
    }
}
