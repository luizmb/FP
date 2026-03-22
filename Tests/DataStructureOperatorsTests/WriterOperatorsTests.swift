import DataStructureOperators
import DataStructure
import Testing
import CoreOperators
import Core

@Suite struct WriterOperatorsTests {

    // MARK: - Functor operators

    @Test func fmapOperator() {
        let w = Writer<[String], Int>(5, ["x"])
        let result = { $0 * 2 } <£> w
        #expect(result.value == 10)
        #expect(result.log == ["x"])
    }

    @Test func flippedFmapOperator() {
        let w = Writer<[String], Int>(3, ["y"])
        let result = w <&> { $0 + 1 }
        #expect(result.value == 4)
        #expect(result.log == ["y"])
    }

    @Test func constReplaceOperator() {
        let w = Writer<[String], Int>(99, ["z"])
        let result = w £> "hello"
        #expect(result.value == "hello")
        #expect(result.log == ["z"])
    }

    @Test func leftConstReplaceOperator() {
        let w = Writer<[String], Int>(99, ["z"])
        let result = "hello" <£ w
        #expect(result.value == "hello")
        #expect(result.log == ["z"])
    }

    // MARK: - Applicative operators

    @Test func applyOperator() {
        let wf = Writer<[String], (Int) -> String>({ "\($0)" }, ["fn"])
        let wa = Writer<[String], Int>(7, ["val"])
        let result = wf <*> wa
        #expect(result.value == "7")
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRightOperator() {
        let a = Writer<[String], Int>(1, ["a"])
        let b = Writer<[String], Int>(2, ["b"])
        let result = a *> b
        #expect(result.value == 2)
        #expect(result.log == ["a", "b"])
    }

    @Test func seqLeftOperator() {
        let a = Writer<[String], Int>(1, ["a"])
        let b = Writer<[String], Int>(2, ["b"])
        let result = a <* b
        #expect(result.value == 1)
        #expect(result.log == ["a", "b"])
    }

    // MARK: - Monad operators

    @Test func bindOperator() {
        let w = Writer<[String], Int>(3, ["outer"])
        let result = w >>- { n in Writer<[String], String>("\(n)", ["inner"]) }
        #expect(result.value == "3")
        #expect(result.log == ["outer", "inner"])
    }

    @Test func flippedBindOperator() {
        let fn: (Int) -> Writer<[String], String> = { n in Writer("\(n)", ["inner"]) }
        let w = Writer<[String], Int>(4, ["outer"])
        let result = fn -<< w
        #expect(result.value == "4")
        #expect(result.log == ["outer", "inner"])
    }

    @Test func kleisliOperator() {
        let step1: (Int) -> Writer<[String], Int> = { n in Writer(n + 1, ["s1"]) }
        let step2: (Int) -> Writer<[String], String> = { n in Writer("\(n)", ["s2"]) }
        let composed = step1 >=> step2
        let result = composed(10)
        #expect(result.value == "11")
        #expect(result.log == ["s1", "s2"])
    }
}
