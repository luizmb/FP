@testable import CoreFP
@testable import CoreFPOperators
import Testing

@Suite struct EndoMutOperatorsTests {
    @Test func semigroupOperator_appliesLhsThenRhs() {
        let addOne = EndoMut<Int> { $0 += 1 }
        let double = EndoMut<Int> { $0 *= 2 }
        var value = 3
        (addOne <> double)(&value)
        #expect(value == 8)   // (3+1)*2
    }

    @Test func semigroupOperator_chain() {
        var items = [3, 1, 4, 1, 5]
        let clamp = EndoMut<[Int]> { xs in for i in xs.indices { xs[i] = min(xs[i], 3) } }
        let sort  = EndoMut<[Int]> { $0.sort() }
        (clamp <> sort)(&items)
        #expect(items == [1, 1, 3, 3, 3])
    }

    @Test func mconcat_pipelineAppliesInOrder() {
        let addOne = EndoMut<Int> { $0 += 1 }
        let double = EndoMut<Int> { $0 *= 2 }
        let addTen = EndoMut<Int> { $0 += 10 }
        var value = 3
        mconcat([addOne, double, addTen])(&value)
        #expect(value == 18)   // ((3+1)*2)+10
    }

    @Test func semigroupOperator_matchesDirectCombine() {
        let addOne = EndoMut<Int> { $0 += 1 }
        let double = EndoMut<Int> { $0 *= 2 }
        var v1 = 5, v2 = 5
        (addOne <> double)(&v1)
        EndoMut.combine(addOne, double).runEndoMut(&v2)
        #expect(v1 == v2)
    }
}
