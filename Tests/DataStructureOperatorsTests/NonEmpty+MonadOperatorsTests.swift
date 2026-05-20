import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct NonEmptyMonadOperatorsTests {
    // MARK: - >>- bind (container left)

    @Test func bindOperator_forward() {
        let ne = NonEmpty(head: 1, tail: [2, 3])
        let result = ne >>- { n in NonEmpty(head: n, tail: [n * 10]) }
        #expect(result.toArray == [1, 10, 2, 20, 3, 30])
    }

    // MARK: - -<< bind (fn left)

    @Test func bindOperator_flipped() {
        let double: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0, tail: [$0]) }
        let result = double -<< NonEmpty(head: 3)
        #expect(result.toArray == [3, 3])
    }

    // MARK: - >=> kleisli (left-to-right)

    @Test func kleisliOperator_leftToRight() {
        let f: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0 + 1) }
        let g: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0 * 2) }
        let fg = f >=> g
        #expect(fg(3).toArray == [8])   // (3+1)*2
    }

    // MARK: - <=< kleisli (right-to-left)

    @Test func kleisliOperator_rightToLeft() {
        let f: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0 + 1) }
        let g: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0 * 2) }
        let gf = g <=< f
        #expect(gf(3).toArray == [8])   // same as f >=> g
    }

    // MARK: - Monad laws via operators

    @Test func monadLaw_leftIdentity() {
        let f: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0 * 2) }
        #expect((NonEmpty.pure(3) >>- f) == f(3))
    }

    @Test func monadLaw_rightIdentity() {
        let ne = NonEmpty(head: 1, tail: [2, 3])
        #expect((ne >>- NonEmpty.pure) == ne)
    }

    @Test func monadLaw_associativity() {
        let ne = NonEmpty(head: 1, tail: [2, 3])
        let f: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0 + 1) }
        let g: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0 * 2) }
        #expect((ne >>- f >>- g) == (ne >>- { f($0) >>- g }))
    }
}
