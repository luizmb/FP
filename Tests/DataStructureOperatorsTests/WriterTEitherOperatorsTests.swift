import DataStructureOperators
import DataStructure
import Testing
import CoreFPOperators
import CoreFP

@Suite struct WriterTEitherOperatorsTests {

    private enum TestL: Equatable { case err }

    @Test func fmapRight() {
        let w = Writer<[String], Either<TestL, Int>>(.right(5), ["log"])
        let result = { $0 * 2 } <£^> w
        #expect(result == Writer<[String], Either<TestL, Int>>(.right(10), ["log"]))
    }

    @Test func flippedFmapRight() {
        let w = Writer<[String], Either<TestL, Int>>(.right(5), ["log"])
        let result = w <&^> { $0 * 2 }
        #expect(result == Writer<[String], Either<TestL, Int>>(.right(10), ["log"]))
    }

    @Test func fmapLeft() {
        let w = Writer<[String], Either<TestL, Int>>(.left(.err), ["log"])
        let result = { $0 * 2 } <£^> w
        #expect(result == Writer<[String], Either<TestL, Int>>(.left(.err), ["log"]))
    }

    @Test func apply() {
        let wf = Writer<[String], Either<TestL, (Int) -> String>>(.right { "\($0)" }, ["fn"])
        let wa = Writer<[String], Either<TestL, Int>>(.right(7), ["val"])
        let result = wf <*> wa
        #expect(result.value == .right("7"))
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs = Writer<[String], Either<TestL, Int>>(.right(1), ["a"])
        let rhs = Writer<[String], Either<TestL, String>>(.right("b"), ["b"])
        let result = lhs *> rhs
        #expect(result.value == .right("b"))
        #expect(result.log == ["a", "b"])
    }

    @Test func seqLeft() {
        let lhs = Writer<[String], Either<TestL, Int>>(.right(1), ["a"])
        let rhs = Writer<[String], Either<TestL, String>>(.right("b"), ["b"])
        let result = lhs <* rhs
        #expect(result.value == .right(1))
        #expect(result.log == ["a", "b"])
    }

    @Test func bind() {
        let w = Writer<[String], Either<TestL, Int>>(.right(5), ["outer"])
        let result = w >>- { n in
            Writer<[String], Either<TestL, String>>(.right("\(n)"), ["inner"])
        }
        #expect(result.value == .right("5"))
        #expect(result.log == ["outer", "inner"])
    }

    @Test func bindLeft() {
        let w = Writer<[String], Either<TestL, Int>>(.left(.err), ["outer"])
        let result = w >>- { n in
            Writer<[String], Either<TestL, String>>(.right("\(n)"), ["inner"])
        }
        #expect(result.value == .left(.err))
        #expect(result.log == ["outer"])
    }

    @Test func kleisli() {
        let f: (Int) -> Writer<[String], Either<TestL, Int>> = { n in Writer(.right(n + 1), ["f"]) }
        let g: (Int) -> Writer<[String], Either<TestL, String>> = { n in Writer(.right("\(n)"), ["g"]) }
        let result = (f >=> g)(4)
        #expect(result.value == .right("5"))
        #expect(result.log == ["f", "g"])
    }
}
