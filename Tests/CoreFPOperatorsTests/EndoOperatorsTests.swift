// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
@testable import CoreFPOperators
import Testing

@Suite struct EndoOperatorsTests {
    @Test func semigroupOperator_appliesLhsThenRhs() {
        let addOne = Endo<Int> { $0 + 1 }
        let double = Endo<Int> { $0 * 2 }
        let combined = addOne <> double
        #expect(combined(3) == 8)   // (3+1)*2
    }

    @Test func semigroupOperator_chain() {
        let trim    = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
        let lower   = Endo<String> { $0.lowercased() }
        let exclaim = Endo<String> { $0 + "!" }
        let pipeline = trim <> lower <> exclaim
        #expect(pipeline("  HELLO  ") == "hello!")
    }

    @Test func mconcat_via_combine() {
        let addOne = Endo<Int> { $0 + 1 }
        let double = Endo<Int> { $0 * 2 }
        let addTen = Endo<Int> { $0 + 10 }
        let pipeline = mconcat([addOne, double, addTen])
        #expect(pipeline(3) == 18)   // (3+1)*2+10
    }
}
