// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterEitherOperatorsTests {
    @Test func eitherTWriterMapOperator() {
        let e: Either<String, Writer<[String], Int>> = .right(Writer(3, ["y"]))
        let result = ({ $0 * 4 } <£> e.eitherT).rawValue
        #expect(result == .right(Writer(12, ["y"])))
    }

    @Test func writerTEitherBind() {
        let w = Writer<[String], Either<String, Int>>(.right(5), ["outer"]).writerT
        let result = (w >>- { (n: Int) in
            Writer<[String], Either<String, String>>(.right("\(n)"), ["inner"]).writerT
        }).rawValue
        #expect(result.value == .right("5"))
        #expect(result.log == ["outer", "inner"])
    }

    @Test func eitherTWriterBindOperator() {
        let e: Either<String, Writer<[String], Int>> = .right(Writer(5, ["outer"]))
        let result = (e.eitherT >>- { n in Either<String, Writer<[String], String>>.right(Writer("\(n)", ["inner"])).eitherT }).rawValue
        #expect(result == .right(Writer("5", ["outer", "inner"])))
    }
}
