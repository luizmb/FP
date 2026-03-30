import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterReaderOperatorsTests {
    @Test func writerMapTWithReaderInner() {
        let w = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["x"])
        let result = { $0 * 3 } <£^> w
        #expect(result.value.runReader(4) == 12)
        #expect(result.log == ["x"])
    }

    @Test func writerFlippedFmapWithReaderInner() {
        let w = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["x"])
        let result = w <&^> { $0 * 3 }
        #expect(result.value.runReader(4) == 12)
        #expect(result.log == ["x"])
    }

    @Test func readerMapTWithWriterInner() {
        let r: Reader<Int, Writer<[String], Int>> = Reader { env in Writer(env, ["y"]) }
        let result = r.mapT { $0 * 5 }
        let w = result.runReader(2)
        #expect(w.value == 10)
        #expect(w.log == ["y"])
    }

    @Test func readerFlatMapTWithWriterInner() {
        let r: Reader<Int, Writer<[String], Int>> = Reader { env in Writer(env, ["outer"]) }
        let result = r.flatMapT { n in Writer<[String], String>("\(n)", ["inner"]) }
        let w = result.runReader(3)
        #expect(w.value == "3")
        #expect(w.log == ["outer", "inner"])
    }

    @Test func writerFlatMapTKeepsOuterLog() {
        let w = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["outer"])
        let result = w >>- { n in
            Writer<[String], Reader<Int, String>>(Reader { env in "\(env + n)" }, ["inner"])
        }
        #expect(result.value.runReader(3) == "6")
        #expect(result.log == ["outer"])
    }

    @Test func readerTWriterApply() {
        let rf: Reader<Int, Writer<[String], (Int) -> String>> = Reader { _ in Writer({ "\($0)" }, ["fn"]) }
        let ra: Reader<Int, Writer<[String], Int>> = Reader { env in Writer(env, ["val"]) }
        let result = rf <*> ra
        let w = result.runReader(7)
        #expect(w.value == "7")
        #expect(w.log == ["fn", "val"])
    }

    @Test func readerTWriterSeqRight() {
        let lhs: Reader<Int, Writer<[String], Int>> = Reader { _ in Writer(1, ["a"]) }
        let rhs: Reader<Int, Writer<[String], String>> = Reader { _ in Writer("hello", ["b"]) }
        let result = lhs *> rhs
        let w = result.runReader(0)
        #expect(w.value == "hello")
        #expect(w.log == ["a", "b"])
    }

    @Test func readerTWriterSeqLeft() {
        let lhs: Reader<Int, Writer<[String], Int>> = Reader { _ in Writer(99, ["a"]) }
        let rhs: Reader<Int, Writer<[String], String>> = Reader { _ in Writer("ignored", ["b"]) }
        let result = lhs <* rhs
        let w = result.runReader(0)
        #expect(w.value == 99)
        #expect(w.log == ["a", "b"])
    }
}
