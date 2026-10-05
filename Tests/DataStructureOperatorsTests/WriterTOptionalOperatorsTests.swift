// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterTOptionalOperatorsTests {
    @Test func apply() {
        let wf = Writer<[String], (@Sendable (Int) -> String)?>(.some { "\($0)" }, ["fn"])
        let wa = Writer<[String], Int?>(.some(7), ["val"])
        let result = (wf.writerT <*> wa.writerT).rawValue
        #expect(result.value == .some("7"))
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs = Writer<[String], Int?>(.some(1), ["a"])
        let rhs = Writer<[String], String?>(.some("b"), ["b"])
        let result = (lhs.writerT *> rhs.writerT).rawValue
        #expect(result.value == .some("b"))
        #expect(result.log == ["a", "b"])
    }

    @Test func seqLeft() {
        let lhs = Writer<[String], Int?>(.some(1), ["a"])
        let rhs = Writer<[String], String?>(.some("b"), ["b"])
        let result = (lhs.writerT <* rhs.writerT).rawValue
        #expect(result.value == .some(1))
        #expect(result.log == ["a", "b"])
    }

    @Test func bind() {
        let w = Writer<[String], Int?>(.some(5), ["outer"])
        let result = (w.writerT >>- { n in Writer<[String], String?>(.some("\(n)"), ["inner"]).writerT }).rawValue
        #expect(result.value == .some("5"))
        #expect(result.log == ["outer", "inner"])
    }

    @Test func bindNone() {
        let w = Writer<[String], Int?>(nil, ["outer"])
        let result = (w.writerT >>- { n in Writer<[String], String?>(.some("\(n)"), ["inner"]).writerT }).rawValue
        #expect(result.value == nil)
        #expect(result.log == ["outer"])
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> WriterTOptional<[String], Int> = { n in WriterTOptional(Writer(.some(n + 1), ["f"])) }
        let g: @Sendable (Int) -> WriterTOptional<[String], String> = { n in WriterTOptional(Writer(.some("\(n)"), ["g"])) }
        let result = (f >=> g)(4).rawValue
        #expect(result.value == .some("5"))
        #expect(result.log == ["f", "g"])
    }
}
