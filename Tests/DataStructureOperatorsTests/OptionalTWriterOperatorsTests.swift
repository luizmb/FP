import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct OptionalTWriterOperatorsTests {
    @Test func fmapSome() {
        let opt: Writer<[String], Int>? = .some(Writer(5, ["x"]))
        let result = { $0 * 2 } <£^> opt
        #expect(result?.value == 10)
        #expect(result?.log == ["x"])
    }

    @Test func flippedFmapSome() {
        let opt: Writer<[String], Int>? = .some(Writer(5, ["x"]))
        let result = opt <&^> { $0 * 2 }
        #expect(result?.value == 10)
        #expect(result?.log == ["x"])
    }

    @Test func fmapNone() {
        let opt: Writer<[String], Int>? = nil
        let result: Writer<[String], Int>? = { $0 * 2 } <£^> opt
        #expect(result == nil)
    }

    @Test func bindSome() {
        let opt: Writer<[String], Int>? = .some(Writer(5, ["outer"]))
        let result = opt >>- { n in Writer<[String], String>("\(n)", ["inner"]) }
        #expect(result?.value == "5")
        #expect(result?.log == ["outer", "inner"])
    }

    @Test func bindNone() {
        let opt: Writer<[String], Int>? = nil
        let result = opt >>- { n in Writer<[String], String>("\(n)", ["inner"]) }
        #expect(result == nil)
    }

    @Test func kleisli() {
        let f: (Int) -> Writer<[String], Int>? = { n in .some(Writer(n + 1, ["f"])) }
        let g: (Int) -> Writer<[String], String> = { n in Writer("\(n)", ["g"]) }
        let result = (f >=> g)(4)
        #expect(result?.value == "5")
        #expect(result?.log == ["f", "g"])
    }

    @Test func apply() {
        let wf: Writer<[String], (Int) -> String>? = Writer({ "\($0)" }, ["fn"])
        let wa: Writer<[String], Int>? = Writer(7, ["val"])
        let result = wf <*> wa
        #expect(result?.value == "7")
        #expect(result?.log == ["fn", "val"])
    }

    @Test func applyNil() {
        let wf: Writer<[String], (Int) -> String>? = nil
        let wa: Writer<[String], Int>? = Writer(7, ["val"])
        let result = wf <*> wa
        #expect(result == nil)
    }

    @Test func seqRight() {
        let lhs: Writer<[String], Int>? = Writer(1, ["a"])
        let rhs: Writer<[String], String>? = Writer("hello", ["b"])
        let result = lhs *> rhs
        #expect(result?.value == "hello")
        #expect(result?.log == ["a", "b"])
    }

    @Test func seqLeft() {
        let lhs: Writer<[String], Int>? = Writer(99, ["a"])
        let rhs: Writer<[String], String>? = Writer("ignored", ["b"])
        let result = lhs <* rhs
        #expect(result?.value == 99)
        #expect(result?.log == ["a", "b"])
    }
}
