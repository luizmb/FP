import DataStructureOperators
import DataStructure
import Testing
import CoreFPOperators
import CoreFP

@Suite struct WriterTReaderOperatorsTests {

    @Test func fmap() {
        let w = Writer<[String], Reader<Int, Int>>(Reader { $0 * 2 }, ["log"])
        let result = { $0 + 1 } <£^> w
        #expect(result.value(3) == 7)
        #expect(result.log == ["log"])
    }

    @Test func flippedFmap() {
        let w = Writer<[String], Reader<Int, Int>>(Reader { $0 * 2 }, ["log"])
        let result = w <&^> { $0 + 1 }
        #expect(result.value(3) == 7)
        #expect(result.log == ["log"])
    }

    @Test func apply() {
        let wf = Writer<[String], Reader<Int, (Int) -> String>>(Reader { env in { "\(env + $0)" } }, ["fn"])
        let wa = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["val"])
        let result = wf <*> wa
        #expect(result.value(5) == "10")
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["a"])
        let rhs = Writer<[String], Reader<Int, String>>(Reader { _ in "done" }, ["b"])
        let result = lhs *> rhs
        #expect(result.value(0) == "done")
        #expect(result.log == ["a", "b"])
    }

    @Test func bind() {
        let w = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["outer"])
        let result = w >>- { n in
            Writer<[String], Reader<Int, String>>(Reader { _ in "\(n)" }, ["inner"])
        }
        // inner log discarded; Reader defers n until run-time
        #expect(result.log == ["outer"])
        // value lazily computes based on n captured at composition time
        let computed = result.value(7)
        #expect(computed == "7")
    }

    @Test func kleisli() {
        let f: (Int) -> Writer<[String], Reader<Int, Int>> = { n in Writer(Reader { $0 + n }, ["f"]) }
        let g: (Int) -> Writer<[String], Reader<Int, String>> = { n in Writer(Reader { _ in "\(n)" }, ["g"]) }
        let result = (f >=> g)(2)
        #expect(result.log == ["f"])
        // result.value is Reader<Int, String> whose output was captured when g was called
        let output = result.value(3) // f produces Reader { 3+2=5 }, g captures 5
        #expect(output == "5")
    }
}
