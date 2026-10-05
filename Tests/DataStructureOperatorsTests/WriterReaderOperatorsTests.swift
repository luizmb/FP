// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterReaderOperatorsTests {
    @Test func readerTWriterMapOperator() {
        let r: Reader<Int, Writer<[String], Int>> = Reader { env in Writer(env, ["y"]) }
        let result = ({ $0 * 5 } <£> r.readerT).rawValue
        let w = result.runReader(2)
        #expect(w.value == 10)
        #expect(w.log == ["y"])
    }

    @Test func readerTWriterBindOperator() {
        let r: Reader<Int, Writer<[String], Int>> = Reader { env in Writer(env, ["outer"]) }
        let next: @Sendable (Int) -> ReaderTWriter<Int, [String], String> = { n in
            Reader { env in Writer("\(n + env)", ["inner"]) }.readerT
        }
        let result = (r.readerT >>- next).rawValue
        let w = result.runReader(3)
        #expect(w.value == "6")
        #expect(w.log == ["outer", "inner"])
    }

    @Test func readerTWriterApply() {
        let fn: @Sendable (Int) -> String = { "\($0)" }
        let rf: Reader<Int, Writer<[String], @Sendable (Int) -> String>> = Reader(const(Writer(fn, ["fn"])))
        let ra: Reader<Int, Writer<[String], Int>> = Reader { env in Writer(env, ["val"]) }
        let result = (rf.readerT <*> ra.readerT).rawValue
        let w = result.runReader(7)
        #expect(w.value == "7")
        #expect(w.log == ["fn", "val"])
    }

    @Test func readerTWriterSeqRight() {
        let lhs: Reader<Int, Writer<[String], Int>> = Reader(const(Writer(1, ["a"])))
        let rhs: Reader<Int, Writer<[String], String>> = Reader(const(Writer("hello", ["b"])))
        let result = (lhs.readerT *> rhs.readerT).rawValue
        let w = result.runReader(0)
        #expect(w.value == "hello")
        #expect(w.log == ["a", "b"])
    }

    @Test func readerTWriterSeqLeft() {
        let lhs: Reader<Int, Writer<[String], Int>> = Reader(const(Writer(99, ["a"])))
        let rhs: Reader<Int, Writer<[String], String>> = Reader(const(Writer("ignored", ["b"])))
        let result = (lhs.readerT <* rhs.readerT).rawValue
        let w = result.runReader(0)
        #expect(w.value == 99)
        #expect(w.log == ["a", "b"])
    }
}
