// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct TheseFunctorOperatorsTests {
    @Test func fmapOperatorThis() {
        let this: These<String, Int> = .this("error")
        #expect(({ $0 * 2 } <£> this) == .this("error"))
    }

    @Test func fmapOperatorThat() {
        let that: These<String, Int> = .that(5)
        #expect(({ $0 * 2 } <£> that) == .that(10))
    }

    @Test func fmapOperatorBoth() {
        let both: These<String, Int> = .both("a", 5)
        #expect(({ $0 * 2 } <£> both) == .both("a", 10))
    }

    @Test func flippedFmapOperator() {
        let both: These<String, Int> = .both("a", 5)
        #expect((both <&> { $0 * 2 }) == .both("a", 10))
    }

    @Test func mapReplaceOperator() {
        let both: These<String, Int> = .both("a", 5)
        #expect((both £> 99) == .both("a", 99))

        let this: These<String, Int> = .this("error")
        #expect((this £> 99) == .this("error"))
    }

    @Test func mapReplaceFlippedOperator() {
        let both: These<String, Int> = .both("a", 5)
        #expect((42 <£ both) == .both("a", 42))
    }
}

@Suite struct TheseApplicativeOperatorsTests {
    @Test func applyOperatorThisFn() {
        let fn: These<String, @Sendable (Int) -> Int> = .this("fn error")
        let arg: These<String, Int> = .that(5)
        #expect((fn <*> arg) == .this("fn error"))
    }

    @Test func applyOperatorThatFnThatArg() {
        let fn: These<String, @Sendable (Int) -> Int> = .that { $0 * 2 }
        let arg: These<String, Int> = .that(5)
        #expect((fn <*> arg) == .that(10))
    }

    @Test func applyOperatorBothFnBothArg() {
        let fn: These<String, @Sendable (Int) -> Int> = .both("a") { $0 * 2 }
        let arg: These<String, Int> = .both("b", 5)
        #expect((fn <*> arg) == .both("ab", 10))
    }

    @Test func applyOperatorBothFnThisArgCombines() {
        let fn: These<String, @Sendable (Int) -> Int> = .both("a") { $0 * 2 }
        let arg: These<String, Int> = .this("b")
        #expect((fn <*> arg) == .this("ab"))
    }

    @Test func sequenceRightOperator() {
        let both1: These<String, Int> = .both("a", 5)
        let both2: These<String, Int> = .both("b", 10)
        #expect((both1 *> both2) == .both("ab", 10))
    }

    @Test func sequenceLeftOperator() {
        let both1: These<String, Int> = .both("a", 5)
        let both2: These<String, Int> = .both("b", 10)
        #expect((both1 <* both2) == .both("ab", 5))
    }
}

@Suite struct TheseMonadOperatorsTests {
    @Test func bindOperatorThis() {
        let this: These<String, Int> = .this("error")
        let result = this >>- { (n: Int) in These<String, Int>.that(n * 2) }
        #expect(result == .this("error"))
    }

    @Test func bindOperatorThat() {
        let that: These<String, Int> = .that(5)
        let result = that >>- { .that($0 * 2) }
        #expect(result == .that(10))
    }

    @Test func bindOperatorBothAccumulates() {
        let both: These<String, Int> = .both("a", 5)
        let result = both >>- { n in These<String, Int>.both("b", n * 2) }
        #expect(result == .both("ab", 10))
    }

    @Test func flippedBindOperator() {
        let transform: @Sendable (Int) -> These<String, Int> = { .that($0 * 2) }
        let that: These<String, Int> = .that(5)
        #expect((transform -<< that) == .that(10))
    }

    @Test func kleisliOperator() {
        let f: @Sendable (Int) -> These<String, Int> = { .that($0 * 2) }
        let g: @Sendable (Int) -> These<String, String> = { .that("\($0)") }

        let composed = f >=> g
        #expect(composed(5) == .that("10"))
    }

    @Test func kleisliBackOperator() {
        let f: @Sendable (Int) -> These<String, Int> = { .that($0 * 2) }
        let g: @Sendable (Int) -> These<String, String> = { .that("\($0)") }

        let composed = g <=< f
        #expect(composed(5) == .that("10"))
    }
}
