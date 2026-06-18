// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct OptionalTStatefulOperatorsTests {
    @Test func fmapSome() {
        let opt: Stateful<Int, Int>? = .some(.get)
        let result = { $0 * 2 } <£^> opt
        #expect(result?.eval(5) == 10)
    }

    @Test func flippedFmapSome() {
        let opt: Stateful<Int, Int>? = .some(.get)
        let result = opt <&^> { $0 * 2 }
        #expect(result?.eval(5) == 10)
    }

    @Test func fmapNone() {
        let opt: Stateful<Int, Int>? = nil
        let result = { $0 * 2 } <£^> opt
        #expect(result == nil)
    }

    @Test func bindSome() {
        let opt: Stateful<Int, Int>? = .some(.get)
        let result = opt >>- { n in Stateful<Int, String>.pure("\(n)") }
        #expect(result?.eval(7) == "7")
    }

    @Test func bindNone() {
        let opt: Stateful<Int, Int>? = nil
        let result = opt >>- { n in Stateful<Int, String>.pure("\(n)") }
        #expect(result == nil)
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> Stateful<Int, Int>? = { n in .some(.pure(n + 1)) }
        let g: @Sendable (Int) -> Stateful<Int, String> = { n in .pure("\(n)") }
        let result = (f >=> g)(3)
        #expect(result?.eval(0) == "4")
    }

    @Test func apply() {
        let sf: Stateful<Int, @Sendable (Int) -> String>? = .pure({ "\($0)" })
        let sa: Stateful<Int, Int>? = .get
        let result = sf <*> sa
        #expect(result?.eval(5) == "5")
    }

    @Test func applyNil() {
        let sf: Stateful<Int, @Sendable (Int) -> String>? = nil
        let sa: Stateful<Int, Int>? = .pure(5)
        let result = sf <*> sa
        #expect(result == nil)
    }

    @Test func seqRight() {
        let lhs: Stateful<Int, Int>? = .pure(1)
        let rhs: Stateful<Int, String>? = .pure("hello")
        let result = lhs *> rhs
        #expect(result?.eval(0) == "hello")
    }

    @Test func seqLeft() {
        let lhs: Stateful<Int, Int>? = .pure(99)
        let rhs: Stateful<Int, String>? = .pure("ignored")
        let result = lhs <* rhs
        #expect(result?.eval(0) == 99)
    }
}
