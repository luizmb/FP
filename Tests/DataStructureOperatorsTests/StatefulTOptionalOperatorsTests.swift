import DataStructureOperators
import DataStructure
import Testing
import CoreFPOperators
import CoreFP

@Suite struct StatefulTOptionalOperatorsTests {

    @Test func fmapSome() {
        let s = Stateful<Int, Int?>.pure(.some(5))
        let result = { $0 * 2 } <£^> s
        #expect(result.eval(0) == .some(10))
    }

    @Test func fmapNone() {
        let s = Stateful<Int, Int?>.pure(nil)
        let result = { $0 * 2 } <£^> s
        #expect(result.eval(0) == nil)
    }

    @Test func apply() {
        let sf = Stateful<Int, ((Int) -> String)?>.pure(.some { "\($0)" })
        let sa = Stateful<Int, Int?>.pure(.some(7))
        let result = sf <*> sa
        #expect(result.eval(0) == .some("7"))
    }

    @Test func applyNone() {
        let sf = Stateful<Int, ((Int) -> String)?>.pure(nil)
        let sa = Stateful<Int, Int?>.pure(.some(7))
        let result = sf <*> sa
        #expect(result.eval(0) == nil)
    }

    @Test func seqRight() {
        let lhs = Stateful<Int, Int?>.pure(.some(1))
        let rhs = Stateful<Int, String?>.pure(.some("b"))
        let result = lhs *> rhs
        #expect(result.eval(0) == .some("b"))
    }

    @Test func seqLeft() {
        let lhs = Stateful<Int, Int?>.pure(.some(1))
        let rhs = Stateful<Int, String?>.pure(.some("b"))
        let result = lhs <* rhs
        #expect(result.eval(0) == .some(1))
    }

    @Test func bind() {
        let s = Stateful<Int, Int?>.pure(.some(5))
        let result = s >>- { n in Stateful<Int, String?>.pure(.some("\(n)")) }
        #expect(result.eval(0) == .some("5"))
    }

    @Test func bindNone() {
        let s = Stateful<Int, Int?>.pure(nil)
        let result = s >>- { n in Stateful<Int, String?>.pure(.some("\(n)")) }
        #expect(result.eval(0) == nil)
    }

    @Test func kleisli() {
        let f: (Int) -> Stateful<Int, Int?> = { n in .pure(.some(n + 1)) }
        let g: (Int) -> Stateful<Int, String?> = { n in .pure(.some("\(n)")) }
        let result = (f >=> g)(4)
        #expect(result.eval(0) == .some("5"))
    }
}
