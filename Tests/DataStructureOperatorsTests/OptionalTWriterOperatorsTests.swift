// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct OptionalTWriterOperatorsTests {
    @Test func bindSome() {
        let opt: Writer<[String], Int>? = .some(Writer(5, ["outer"]))
        let fn: @Sendable (Int) -> OptionalTWriter<[String], String> = { n in OptionalTWriter(Writer("\(n)", ["inner"])) }
        #expect((opt.optionalT >>- fn).rawValue == Writer("5", ["outer", "inner"]))
    }

    @Test func bindNone() {
        let opt: Writer<[String], Int>? = nil
        let fn: @Sendable (Int) -> OptionalTWriter<[String], String> = { n in OptionalTWriter(Writer("\(n)", ["inner"])) }
        #expect((opt.optionalT >>- fn).rawValue == nil)
    }

    @Test func bindContinuationFails() {
        let opt: Writer<[String], Int>? = .some(Writer(5, ["outer"]))
        let fn: @Sendable (Int) -> OptionalTWriter<[String], String> = const(OptionalTWriter(nil))
        #expect((opt.optionalT >>- fn).rawValue == nil)
    }

    @Test func flippedBind() {
        let opt: Writer<[String], Int>? = .some(Writer(5, ["outer"]))
        let fn: @Sendable (Int) -> OptionalTWriter<[String], String> = { n in OptionalTWriter(Writer("\(n)", ["inner"])) }
        #expect((fn -<< opt.optionalT).rawValue == Writer("5", ["outer", "inner"]))
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> OptionalTWriter<[String], Int> = { n in OptionalTWriter(.some(Writer(n + 1, ["f"]))) }
        let g: @Sendable (Int) -> OptionalTWriter<[String], String> = { n in OptionalTWriter(Writer("\(n)", ["g"])) }
        let none: @Sendable (Int) -> OptionalTWriter<[String], String> = const(OptionalTWriter(nil))
        #expect((f >=> g)(4).rawValue == Writer("5", ["f", "g"]))
        #expect((f >=> none)(4).rawValue == nil)
    }

    @Test func reverseKleisli() {
        let f: @Sendable (Int) -> OptionalTWriter<[String], Int> = { n in OptionalTWriter(.some(Writer(n + 1, ["f"]))) }
        let g: @Sendable (Int) -> OptionalTWriter<[String], String> = { n in OptionalTWriter(Writer("\(n)", ["g"])) }
        #expect((g <=< f)(4).rawValue == Writer("5", ["f", "g"]))
    }

    @Test func apply() {
        let wf: Writer<[String], @Sendable (Int) -> String>? = Writer({ "\($0)" }, ["fn"])
        let wa: Writer<[String], Int>? = Writer(7, ["val"])
        let result = (wf.optionalT <*> wa.optionalT).rawValue
        #expect(result?.value == "7")
        #expect(result?.log == ["fn", "val"])
    }

    @Test func applyNil() {
        let wf: Writer<[String], @Sendable (Int) -> String>? = nil
        let wa: Writer<[String], Int>? = Writer(7, ["val"])
        let result = (wf.optionalT <*> wa.optionalT).rawValue
        #expect(result == nil)
    }

    @Test func seqRight() {
        let lhs: Writer<[String], Int>? = Writer(1, ["a"])
        let rhs: Writer<[String], String>? = Writer("hello", ["b"])
        let result = (lhs.optionalT *> rhs.optionalT).rawValue
        #expect(result?.value == "hello")
        #expect(result?.log == ["a", "b"])
    }

    @Test func seqLeft() {
        let lhs: Writer<[String], Int>? = Writer(99, ["a"])
        let rhs: Writer<[String], String>? = Writer("ignored", ["b"])
        let result = (lhs.optionalT <* rhs.optionalT).rawValue
        #expect(result?.value == 99)
        #expect(result?.log == ["a", "b"])
    }
}
