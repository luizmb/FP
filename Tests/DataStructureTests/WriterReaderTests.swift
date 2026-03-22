import DataStructure
import Testing
import CoreFP

@Suite struct WriterReaderTests {

    // MARK: - Writer<W, Reader<Env, A>> — Writer as outer, Reader as inner

    @Test func mapT() {
        let w = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["log"])
        let mapped = w.mapT { $0 * 2 }
        #expect(mapped.value.runReader(5) == 10)
        #expect(mapped.log == ["log"])
    }

    @Test func applicativeLogsAccumulate() {
        let wf = Writer<[String], Reader<Int, (Int) -> String>>(
            Reader { env in { "\(env + $0)" } },
            ["fn"]
        )
        let wa = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["val"])
        let result = applyWriterReader(wf, wa)
        #expect(result.value.runReader(3) == "6")
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRightWriterReaderLogsAccumulate() {
        let lhs = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["a"])
        let rhs = Writer<[String], Reader<Int, String>>(Reader { "\($0)" }, ["b"])
        let result = seqRightWriterReader(lhs, rhs)
        #expect(result.value.runReader(7) == "7")
        #expect(result.log == ["a", "b"])
    }

    @Test func flatMapTKeepsOuterLog() {
        let w = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["outer"])
        let result = w.flatMapT { n in
            Writer<[String], Reader<Int, String>>(Reader { env in "\(env + n)" }, ["inner"])
        }
        // inner log is discarded
        #expect(result.value.runReader(3) == "6")
        #expect(result.log == ["outer"])
    }

    // MARK: - Reader<Env, Writer<W, A>> — Reader as outer, Writer as inner

    @Test func readerTWriterMapT() {
        let r: Reader<Int, Writer<[String], Int>> = Reader { env in Writer(env, ["x"]) }
        let mapped = r.mapT { $0 * 2 }
        let w = mapped.runReader(4)
        #expect(w.value == 8)
        #expect(w.log == ["x"])
    }

    @Test func readerTWriterFlatMapT() {
        let r: Reader<Int, Writer<[String], Int>> = Reader { env in Writer(env, ["outer"]) }
        let result = r.flatMapT { n in Writer<[String], String>("\(n)", ["inner"]) }
        let w = result.runReader(5)
        #expect(w.value == "5")
        #expect(w.log == ["outer", "inner"])
    }
}
