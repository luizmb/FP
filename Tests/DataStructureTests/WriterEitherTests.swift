// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct WriterEitherTests {
    // MARK: - Writer<W, Either<L, A>> — Writer as outer, Either as inner

    @Test func mapRight() {
        let w = Writer<[String], Either<String, Int>>(.right(5), ["log"])
        let mapped = w.writerT.map { $0 * 2 }.rawValue
        #expect(mapped.value == .right(10))
        #expect(mapped.log == ["log"])
    }

    @Test func mapLeft() {
        let w = Writer<[String], Either<String, Int>>(.left("err"), ["log"])
        let mapped = w.writerT.map { $0 * 2 }.rawValue
        #expect(mapped.value == .left("err"))
        #expect(mapped.log == ["log"])
    }

    @Test func flatMapRight() {
        let w = Writer<[String], Either<String, Int>>(.right(3), ["outer"])
        let result = w.writerT.flatMap { n in
            Writer<[String], Either<String, String>>(.right("\(n)"), ["inner"]).writerT
        }.rawValue
        #expect(result.value == .right("3"))
        #expect(result.log == ["outer", "inner"])
    }

    @Test func flatMapLeft() {
        let w = Writer<[String], Either<String, Int>>(.left("fail"), ["outer"])
        let result = w.writerT.flatMap { n in
            Writer<[String], Either<String, String>>(.right("\(n)"), ["inner"]).writerT
        }.rawValue
        #expect(result.value == .left("fail"))
        #expect(result.log == ["outer"])
    }

    @Test func applicative() {
        let wf = Writer<[String], Either<String, @Sendable (Int) -> String>>(
            .right { "\($0)" },
            ["fn"]
        )
        let wa = Writer<[String], Either<String, Int>>(.right(7), ["val"])
        let result = WriterTEither.apply(wf.writerT, wa.writerT).rawValue
        #expect(result.value == .right("7"))
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs = Writer<[String], Either<String, Int>>(.right(1), ["a"])
        let rhs = Writer<[String], Either<String, Int>>(.right(2), ["b"])
        let result = lhs.writerT.seqRight(rhs.writerT).rawValue
        #expect(result.value == .right(2))
        #expect(result.log == ["a", "b"])
    }

    // MARK: - Either<L, Writer<W, A>> — Either as outer, Writer as inner

    @Test func eitherTWriterMapTRight() {
        let e: Either<String, Writer<[String], Int>> = .right(Writer(4, ["x"]))
        let mapped = e.mapT { $0 * 3 }
        #expect(mapped == .right(Writer(12, ["x"])))
    }

    @Test func eitherTWriterMapTLeft() {
        let e: Either<String, Writer<[String], Int>> = .left("err")
        let mapped: Either<String, Writer<[String], Int>> = e.mapT { $0 * 3 }
        #expect(mapped == .left("err"))
    }

    @Test func eitherTWriterFlatMapTRight() {
        let e: Either<String, Writer<[String], Int>> = .right(Writer(5, ["outer"]))
        let result = e.flatMapT { n in Either<String, Writer<[String], String>>.right(Writer("\(n)", ["inner"])) }
        #expect(result == .right(Writer("5", ["outer", "inner"])))
    }

    @Test func eitherTWriterFlatMapTLeft() {
        let e: Either<String, Writer<[String], Int>> = .left("nope")
        let result = e.flatMapT { n in Either<String, Writer<[String], String>>.right(Writer("\(n)", ["inner"])) }
        #expect(result == .left("nope"))
    }
}
