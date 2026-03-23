import DataStructureOperators
import DataStructure
import Testing
import CoreFPOperators
import CoreFP

@Suite struct WriterEitherOperatorsTests {

    @Test func writerMapTWithEitherInner() {
        let w = Writer<[String], Either<String, Int>>(.right(5), ["x"])
        let result = { $0 * 2 } <£^> w
        #expect(result.value == .right(10))
        #expect(result.log == ["x"])
    }

    @Test func eitherMapTWithWriterInner() {
        let e: Either<String, Writer<[String], Int>> = .right(Writer(3, ["y"]))
        let result = e.mapT { $0 * 4 }
        #expect(result == .right(Writer(12, ["y"])))
    }

    @Test func writerFlatMapT() {
        let w = Writer<[String], Either<String, Int>>(.right(5), ["outer"])
        let result = w >>- { n in
            Writer<[String], Either<String, String>>(.right("\(n)"), ["inner"])
        }
        #expect(result.value == .right("5"))
        #expect(result.log == ["outer", "inner"])
    }

    @Test func eitherFlatMapTWithWriterInner() {
        let e: Either<String, Writer<[String], Int>> = .right(Writer(5, ["outer"]))
        let result = e.flatMapT { n in Writer<[String], String>("\(n)", ["inner"]) }
        #expect(result == .right(Writer("5", ["outer", "inner"])))
    }
}
