import Testing
import WriterReaderOperators
import WriterReader
import WriterOperators
import ReaderOperators
import Writer
import Reader
import FP

@Suite struct WriterReaderOperatorsTests {

    @Test func writerMapTWithReaderInner() {
        let w = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["x"])
        let result = w.mapT { $0 * 3 }
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
        let result = w.flatMapT { n in
            Writer<[String], Reader<Int, String>>(Reader { env in "\(env + n)" }, ["inner"])
        }
        #expect(result.value.runReader(3) == "6")
        #expect(result.log == ["outer"])
    }
}
