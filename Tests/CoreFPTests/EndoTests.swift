@testable import CoreFP
import Testing

@Suite struct EndoTests {
    // MARK: - Construction and application

    @Test func runEndo() {
        let e = Endo<Int> { $0 + 1 }
        #expect(e.runEndo(5) == 6)
    }

    @Test func callAsFunction() {
        let e = Endo<Int> { $0 * 2 }
        #expect(e(3) == 6)
    }

    @Test func endoFreeFunction() {
        let e = endo { (s: String) in s.uppercased() }
        #expect(e.runEndo("hello") == "HELLO")
    }

    // MARK: - Semigroup

    @Test func combine_appliesLhsThenRhs() {
        let addOne = Endo<Int> { $0 + 1 }
        let double = Endo<Int> { $0 * 2 }
        let combined = Endo.combine(addOne, double)
        #expect(combined.runEndo(3) == 8)   // (3+1)*2
    }

    @Test func combine_associativity() {
        let addOne = Endo<Int> { $0 + 1 }
        let double = Endo<Int> { $0 * 2 }
        let addTen = Endo<Int> { $0 + 10 }
        let left  = Endo.combine(Endo.combine(addOne, double), addTen)
        let right = Endo.combine(addOne, Endo.combine(double, addTen))
        #expect(left.runEndo(3) == right.runEndo(3))
    }

    // MARK: - Monoid

    @Test func identity_isNeutralLeft() {
        let addOne = Endo<Int> { $0 + 1 }
        let combined = Endo.combine(.identity, addOne)
        #expect(combined.runEndo(5) == addOne.runEndo(5))
    }

    @Test func identity_isNeutralRight() {
        let addOne = Endo<Int> { $0 + 1 }
        let combined = Endo.combine(addOne, .identity)
        #expect(combined.runEndo(5) == addOne.runEndo(5))
    }

    @Test func mconcat_pipelineAppliesInOrder() {
        let trim    = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
        let lower   = Endo<String> { $0.lowercased() }
        let exclaim = Endo<String> { $0 + "!" }
        let pipeline = mconcat([trim, lower, exclaim])
        #expect(pipeline.runEndo("  HELLO  ") == "hello!")
    }

    @Test func mconcat_empty_isIdentity() {
        let empty = mconcat([Endo<Int>]())
        #expect(empty.runEndo(42) == 42)
    }
}
