import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterTOptionalOperatorsTests {
    @Test func fmapSome() {
        let w = Writer<[String], Int?>(.some(5), ["log"])
        let result = { $0 * 2 } <£^> w
        #expect(result.value == .some(10))
        #expect(result.log == ["log"])
    }

    @Test func flippedFmapSome() {
        let w = Writer<[String], Int?>(.some(5), ["log"])
        let result = w <&^> { $0 * 2 }
        #expect(result.value == .some(10))
        #expect(result.log == ["log"])
    }

    @Test func fmapNone() {
        let w = Writer<[String], Int?>(nil, ["log"])
        let result = { $0 * 2 } <£^> w
        #expect(result.value == nil)
        #expect(result.log == ["log"])
    }

    @Test func apply() {
        let wf = Writer<[String], (@Sendable (Int) -> String)?>(.some { "\($0)" }, ["fn"])
        let wa = Writer<[String], Int?>(.some(7), ["val"])
        let result = wf <*> wa
        #expect(result.value == .some("7"))
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs = Writer<[String], Int?>(.some(1), ["a"])
        let rhs = Writer<[String], String?>(.some("b"), ["b"])
        let result = lhs *> rhs
        #expect(result.value == .some("b"))
        #expect(result.log == ["a", "b"])
    }

    @Test func seqLeft() {
        let lhs = Writer<[String], Int?>(.some(1), ["a"])
        let rhs = Writer<[String], String?>(.some("b"), ["b"])
        let result = lhs <* rhs
        #expect(result.value == .some(1))
        #expect(result.log == ["a", "b"])
    }

    @Test func bind() {
        let w = Writer<[String], Int?>(.some(5), ["outer"])
        let result = w >>- { n in Writer<[String], String?>(.some("\(n)"), ["inner"]) }
        #expect(result.value == .some("5"))
        #expect(result.log == ["outer", "inner"])
    }

    @Test func bindNone() {
        let w = Writer<[String], Int?>(nil, ["outer"])
        let result = w >>- { n in Writer<[String], String?>(.some("\(n)"), ["inner"]) }
        #expect(result.value == nil)
        #expect(result.log == ["outer"])
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> Writer<[String], Int?> = { n in Writer(.some(n + 1), ["f"]) }
        let g: @Sendable (Int) -> Writer<[String], String?> = { n in Writer(.some("\(n)"), ["g"]) }
        let result = (f >=> g)(4)
        #expect(result.value == .some("5"))
        #expect(result.log == ["f", "g"])
    }
}
