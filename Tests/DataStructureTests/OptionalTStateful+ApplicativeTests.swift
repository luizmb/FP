// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct OptionalTStatefulApplicativeTests {
    // MARK: - Stateful<S, A>? — Optional as outer, Stateful as inner

    @Test func applyBothSome() {
        let sf: Stateful<Int, @Sendable (Int) -> String>? = .pure { "\($0)" }
        let sa: Stateful<Int, Int>? = .get
        let result = OptionalTStateful.apply(sf.optionalT, sa.optionalT).rawValue
        #expect(result?.eval(5) == "5")
    }

    @Test func applyNilFn() {
        let sf: Stateful<Int, @Sendable (Int) -> String>? = nil
        let sa: Stateful<Int, Int>? = .pure(5)
        let result = OptionalTStateful.apply(sf.optionalT, sa.optionalT).rawValue
        #expect(result == nil)
    }

    @Test func applyNilVal() {
        let sf: Stateful<Int, @Sendable (Int) -> String>? = .pure { "\($0)" }
        let sa: Stateful<Int, Int>? = nil
        let result = OptionalTStateful.apply(sf.optionalT, sa.optionalT).rawValue
        #expect(result == nil)
    }

    @Test func applyBothNil() {
        let sf: Stateful<Int, @Sendable (Int) -> String>? = nil
        let sa: Stateful<Int, Int>? = nil
        let result = OptionalTStateful.apply(sf.optionalT, sa.optionalT).rawValue
        #expect(result == nil)
    }

    @Test func seqRightBothSome() {
        let lhs: Stateful<Int, Int>? = .pure(1)
        let rhs: Stateful<Int, String>? = .pure("hello")
        let result = lhs.optionalT.seqRight(rhs.optionalT).rawValue
        #expect(result?.eval(0) == "hello")
    }

    @Test func seqRightNil() {
        let lhs: Stateful<Int, Int>? = nil
        let rhs: Stateful<Int, String>? = .pure("hello")
        let result = lhs.optionalT.seqRight(rhs.optionalT).rawValue
        #expect(result == nil)
    }

    @Test func seqLeftBothSome() {
        let lhs: Stateful<Int, Int>? = .pure(99)
        let rhs: Stateful<Int, String>? = .pure("ignored")
        let result = lhs.optionalT.seqLeft(rhs.optionalT).rawValue
        #expect(result?.eval(0) == 99)
    }

    @Test func seqLeftNilRight() {
        let lhs: Stateful<Int, Int>? = .pure(99)
        let rhs: Stateful<Int, String>? = nil
        let result = lhs.optionalT.seqLeft(rhs.optionalT).rawValue
        #expect(result == nil)
    }
}
