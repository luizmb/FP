// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct StatefulTOptionalOperatorsTests {
    @Test func apply() {
        let sf = Stateful<Int, (@Sendable (Int) -> String)?>.pure(.some { "\($0)" })
        let sa = Stateful<Int, Int?>.pure(.some(7))
        let result = sf.statefulT <*> sa.statefulT
        #expect(result.rawValue.eval(0) == .some("7"))
    }

    @Test func applyNone() {
        let sf = Stateful<Int, (@Sendable (Int) -> String)?>.pure(nil)
        let sa = Stateful<Int, Int?>.pure(.some(7))
        let result = sf.statefulT <*> sa.statefulT
        #expect(result.rawValue.eval(0) == nil)
    }

    @Test func seqRight() {
        let lhs = Stateful<Int, Int?>.pure(.some(1))
        let rhs = Stateful<Int, String?>.pure(.some("b"))
        let result = lhs.statefulT *> rhs.statefulT
        #expect(result.rawValue.eval(0) == .some("b"))
    }

    @Test func seqLeft() {
        let lhs = Stateful<Int, Int?>.pure(.some(1))
        let rhs = Stateful<Int, String?>.pure(.some("b"))
        let result = lhs.statefulT <* rhs.statefulT
        #expect(result.rawValue.eval(0) == .some(1))
    }

    @Test func bind() {
        let s = Stateful<Int, Int?>.pure(.some(5))
        let result = s.statefulT >>- { n in Stateful<Int, String?>.pure(.some("\(n)")).statefulT }
        #expect(result.rawValue.eval(0) == .some("5"))
    }

    @Test func bindNone() {
        let s = Stateful<Int, Int?>.pure(nil)
        let result = s.statefulT >>- { n in Stateful<Int, String?>.pure(.some("\(n)")).statefulT }
        #expect(result.rawValue.eval(0) == nil)
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> StatefulTOptional<Int, Int> = { n in StatefulTOptional(.pure(.some(n + 1))) }
        let g: @Sendable (Int) -> StatefulTOptional<Int, String> = { n in StatefulTOptional(.pure(.some("\(n)"))) }
        let result = (f >=> g)(4)
        #expect(result.rawValue.eval(0) == .some("5"))
    }
}
