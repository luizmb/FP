// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct WriterReaderTests {
    // MARK: - Writer<W, Reader<Env, A>> — Writer as outer, Reader as inner

    @Test func map() {
        let w = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["log"])
        let mapped = w.writerT.map { $0 * 2 }.rawValue
        #expect(mapped.value.runReader(5) == 10)
        #expect(mapped.log == ["log"])
    }

    @Test func applicativeLogsAccumulate() {
        let wf = Writer<[String], Reader<Int, @Sendable (Int) -> String>>(
            Reader { env in { "\(env + $0)" } },
            ["fn"]
        )
        let wa = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["val"])
        let result = WriterTReader.apply(wf.writerT, wa.writerT).rawValue
        #expect(result.value.runReader(3) == "6")
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRightWriterReaderLogsAccumulate() {
        let lhs = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["a"])
        let rhs = Writer<[String], Reader<Int, String>>(Reader { "\($0)" }, ["b"])
        let result = lhs.writerT.seqRight(rhs.writerT).rawValue
        #expect(result.value.runReader(7) == "7")
        #expect(result.log == ["a", "b"])
    }

    // MARK: - Reader<Env, Writer<W, A>> — Reader as outer, Writer as inner

    @Test func readerTWriterMap() {
        let r: Reader<Int, Writer<[String], Int>> = Reader { env in Writer(env, ["x"]) }
        let mapped = r.readerT.map { $0 * 2 }.rawValue
        let w = mapped.runReader(4)
        #expect(w.value == 8)
        #expect(w.log == ["x"])
    }

    @Test func readerTWriterFlatMap() {
        let r: Reader<Int, Writer<[String], Int>> = Reader { env in Writer(env, ["outer"]) }
        let result = r.readerT.flatMap { n in
            ReaderTWriter(Reader<Int, Writer<[String], String>> { env in Writer("\(n * env)", ["inner"]) })
        }.rawValue
        let w = result.runReader(5)
        #expect(w.value == "25")
        #expect(w.log == ["outer", "inner"])
    }
}
