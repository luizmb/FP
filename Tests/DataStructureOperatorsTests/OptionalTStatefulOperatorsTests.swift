// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct OptionalTStatefulOperatorsTests {
    @Test func apply() {
        let sf: Stateful<Int, @Sendable (Int) -> String>? = .pure { "\($0)" }
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
