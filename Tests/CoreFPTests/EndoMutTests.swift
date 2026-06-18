// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

@Suite struct EndoMutTests {
    // MARK: - Construction and application

    @Test func runEndoMut() {
        var value = 5
        let e = EndoMut<Int> { $0 += 1 }
        e.runEndoMut(&value)
        #expect(value == 6)
    }

    @Test func callAsFunction() {
        var value = 3
        let e = EndoMut<Int> { $0 *= 2 }
        e(&value)
        #expect(value == 6)
    }

    @Test func endoMutFreeFunction() {
        var value = "hello"
        let e = endoMut { (s: inout String) in s = s.uppercased() }
        e.runEndoMut(&value)
        #expect(value == "HELLO")
    }

    // MARK: - Semigroup

    @Test func combine_appliesLhsThenRhs() {
        var value = 3
        let addOne = EndoMut<Int> { $0 += 1 }
        let double = EndoMut<Int> { $0 *= 2 }
        let combined = EndoMut.combine(addOne, double)
        combined.runEndoMut(&value)
        #expect(value == 8)   // (3+1)*2
    }

    @Test func combine_rhsSeesLhsMutation() {
        // rhs closure runs on the value already mutated by lhs
        var value = 0
        let setToFive  = EndoMut<Int> { $0 = 5 }
        let addToValue = EndoMut<Int> { $0 += 3 }
        EndoMut.combine(setToFive, addToValue).runEndoMut(&value)
        #expect(value == 8)   // 5+3, not 0+3
    }

    @Test func combine_associativity() {
        let addOne = EndoMut<Int> { $0 += 1 }
        let double = EndoMut<Int> { $0 *= 2 }
        let addTen = EndoMut<Int> { $0 += 10 }
        let left  = EndoMut.combine(EndoMut.combine(addOne, double), addTen)
        let right = EndoMut.combine(addOne, EndoMut.combine(double, addTen))
        var lv = 3, rv = 3
        left.runEndoMut(&lv)
        right.runEndoMut(&rv)
        #expect(lv == rv)
    }

    // MARK: - Monoid

    @Test func identity_isNeutralLeft() {
        var value = 5
        let addOne = EndoMut<Int> { $0 += 1 }
        EndoMut<Int>.combine(.identity, addOne).runEndoMut(&value)
        #expect(value == 6)
    }

    @Test func identity_isNeutralRight() {
        var value = 5
        let addOne = EndoMut<Int> { $0 += 1 }
        EndoMut<Int>.combine(addOne, .identity).runEndoMut(&value)
        #expect(value == 6)
    }

    @Test func identity_doesNothing() {
        var value = 42
        EndoMut<Int>.identity.runEndoMut(&value)
        #expect(value == 42)
    }

    @Test func mconcat_pipelineAppliesInOrder() {
        var items = [3, 1, 4, 1, 5]
        let clamp = EndoMut<[Int]> { xs in for i in xs.indices { xs[i] = min(xs[i], 3) } }
        let sort  = EndoMut<[Int]> { $0.sort() }
        mconcat([clamp, sort]).runEndoMut(&items)
        #expect(items == [1, 1, 3, 3, 3])
    }

    @Test func mconcat_empty_isIdentity() {
        var value = 42
        mconcat([EndoMut<Int>]()).runEndoMut(&value)
        #expect(value == 42)
    }

    @Test func mconcat_single_isSelf() {
        var value = 3
        mconcat([EndoMut<Int> { $0 += 1 }]).runEndoMut(&value)
        #expect(value == 4)
    }

    // MARK: - Bridge: Endo → EndoMut

    @Test func toEndoMut_preservesSemantics() {
        var value = 5
        Endo<Int> { $0 + 1 }.toEndoMut().runEndoMut(&value)
        #expect(value == 6)
    }

    @Test func toEndoMut_identity_mapsToIdentity() {
        var value = 7
        Endo<Int>.identity.toEndoMut().runEndoMut(&value)
        #expect(value == 7)
    }

    @Test func toEndoMut_preservesCombineOrder() {
        let addOne = Endo<Int> { $0 + 1 }
        let double = Endo<Int> { $0 * 2 }
        let endoCombined = Endo.combine(addOne, double)
        let bridgedCombined = EndoMut.combine(addOne.toEndoMut(), double.toEndoMut())
        var value = 3
        bridgedCombined.runEndoMut(&value)
        #expect(value == endoCombined.runEndo(3))   // (3+1)*2 = 8
    }

    // MARK: - Bridge: EndoMut → Endo

    @Test func toEndo_preservesSemantics() {
        let e = EndoMut<Int> { $0 += 1 }
        #expect(e.toEndo().runEndo(5) == 6)
    }

    @Test func toEndo_identity_mapsToIdentity() {
        #expect(EndoMut<Int>.identity.toEndo().runEndo(42) == 42)
    }

    @Test func toEndo_doesNotMutateOriginal() {
        // toEndo must not change the value at the call site
        let value = 10
        let result = EndoMut<Int> { $0 += 5 }.toEndo().runEndo(value)
        #expect(value == 10)
        #expect(result == 15)
    }

    // MARK: - Bridge round-trips

    @Test func roundTrip_endoMutToEndoToEndoMut() {
        let original = EndoMut<Int> { $0 += 1 }
        let roundTripped = original.toEndo().toEndoMut()
        var v1 = 5, v2 = 5
        original.runEndoMut(&v1)
        roundTripped.runEndoMut(&v2)
        #expect(v1 == v2)
    }

    @Test func roundTrip_endoToEndoMutToEndo() {
        let original = Endo<Int> { $0 + 1 }
        let roundTripped = original.toEndoMut().toEndo()
        #expect(original.runEndo(5) == roundTripped.runEndo(5))
    }
}
