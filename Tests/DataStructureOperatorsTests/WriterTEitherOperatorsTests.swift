// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterTEitherOperatorsTests {
    private enum TestL: Equatable { case err }

    @Test func apply() {
        let wf = Writer<[String], Either<TestL, @Sendable (Int) -> String>>(.right { "\($0)" }, ["fn"])
        let wa = Writer<[String], Either<TestL, Int>>(.right(7), ["val"])
        let result = (wf.writerT <*> wa.writerT).rawValue
        #expect(result.value == .right("7"))
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs = Writer<[String], Either<TestL, Int>>(.right(1), ["a"])
        let rhs = Writer<[String], Either<TestL, String>>(.right("b"), ["b"])
        let result = (lhs.writerT *> rhs.writerT).rawValue
        #expect(result.value == .right("b"))
        #expect(result.log == ["a", "b"])
    }

    @Test func seqLeft() {
        let lhs = Writer<[String], Either<TestL, Int>>(.right(1), ["a"])
        let rhs = Writer<[String], Either<TestL, String>>(.right("b"), ["b"])
        let result = (lhs.writerT <* rhs.writerT).rawValue
        #expect(result.value == .right(1))
        #expect(result.log == ["a", "b"])
    }

    @Test func bind() {
        let w = Writer<[String], Either<TestL, Int>>(.right(5), ["outer"])
        let result = (w.writerT >>- { n in
            Writer<[String], Either<TestL, String>>(.right("\(n)"), ["inner"]).writerT
        }).rawValue
        #expect(result.value == .right("5"))
        #expect(result.log == ["outer", "inner"])
    }

    @Test func bindLeft() {
        let w = Writer<[String], Either<TestL, Int>>(.left(.err), ["outer"])
        let result = (w.writerT >>- { n in
            Writer<[String], Either<TestL, String>>(.right("\(n)"), ["inner"]).writerT
        }).rawValue
        #expect(result.value == .left(.err))
        #expect(result.log == ["outer"])
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> WriterTEither<[String], TestL, Int> = { n in WriterTEither(Writer(.right(n + 1), ["f"])) }
        let g: @Sendable (Int) -> WriterTEither<[String], TestL, String> = { n in WriterTEither(Writer(.right("\(n)"), ["g"])) }
        let result = (f >=> g)(4).rawValue
        #expect(result.value == .right("5"))
        #expect(result.log == ["f", "g"])
    }
}
