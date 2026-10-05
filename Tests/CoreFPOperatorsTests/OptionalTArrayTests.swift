// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators

// swiftlint:disable discouraged_optional_collection
import Testing

@Suite struct OptionalTArrayTests {
    private let add: @Sendable (Int) -> @Sendable (Int) -> Int = { x in { y in x + y } }

    // MARK: - Functor

    @Test func mapSome() {
        let opt: [Int]? = [1, 2, 3]
        let result = { $0 * 2 } <£> opt.optionalT
        #expect(result.rawValue == [2, 4, 6])
    }

    @Test func mapNone() {
        let opt: [Int]? = nil
        let result = opt.optionalT <&> { $0 * 2 }
        #expect(result.rawValue == nil)
    }

    // MARK: - Applicative

    @Test func liftA2BothPresent() {
        let a: [Int]? = [1, 2]
        let b: [Int]? = [10, 20]
        let result = add <£> a.optionalT <*> b.optionalT
        #expect(result.rawValue == [11, 21, 12, 22])
    }

    @Test func liftA2LeftNil() {
        let a: [Int]? = nil
        let b: [Int]? = [10, 20]
        let result = add <£> a.optionalT <*> b.optionalT
        #expect(result.rawValue == nil)
    }

    @Test func liftA2RightNil() {
        let a: [Int]? = [1, 2]
        let b: [Int]? = nil
        let result = add <£> a.optionalT <*> b.optionalT
        #expect(result.rawValue == nil)
    }

    @Test func seqRightBothPresent() {
        let a: [Int]? = [1, 2]
        let b: [String]? = ["x", "y"]
        let result = a.optionalT *> b.optionalT
        #expect(result.rawValue == ["x", "y"])
    }

    @Test func seqRightLeftNil() {
        let a: [Int]? = nil
        let b: [String]? = ["x"]
        let result = a.optionalT *> b.optionalT
        #expect(result.rawValue == nil)
    }

    @Test func seqLeftBothPresent() {
        let a: [Int]? = [1, 2]
        let b: [String]? = ["x", "y"]
        let result = a.optionalT <* b.optionalT
        #expect(result.rawValue == [1, 2])
    }

    // MARK: - Monad

    @Test func bindSomeAllSucceed() {
        let opt: [Int]? = [1, 2, 3]
        let result = opt.optionalT >>- { n in OptionalTArray([n, n * 10]) }
        #expect(result.rawValue == [1, 10, 2, 20, 3, 30])
    }

    @Test func bindSomeOneNil() {
        let opt: [Int]? = [1, 2, 3]
        let result = opt.optionalT >>- { n in
            OptionalTArray(n == 2 ? nil : [n, n * 10])
        }
        #expect(result.rawValue == nil)
    }

    @Test func bindNone() {
        let opt: [Int]? = nil
        let result = opt.optionalT >>- { n in OptionalTArray([n * 2]) }
        #expect(result.rawValue == nil)
    }

    @Test func bindEmpty() {
        let opt: [Int]? = []
        let result = { n in OptionalTArray([n * 2]) } -<< opt.optionalT
        #expect(result.rawValue == [])
    }

    @Test func bindOperator() {
        let opt: [Int]? = [1, 2]
        let result = opt.optionalT >>- { n in OptionalTArray([n, n + 100]) }
        #expect(result.rawValue == [1, 101, 2, 102])
    }

    @Test func kleisliOperator() {
        let f: @Sendable (Int) -> OptionalTArray<Int> = { n in OptionalTArray([n, n * 2]) }
        let g: @Sendable (Int) -> OptionalTArray<String> = { n in OptionalTArray(["\(n)"]) }
        let h = f >=> g
        #expect(h(3).rawValue == ["3", "6"])
        #expect((g <=< f)(3).rawValue == ["3", "6"])
    }
}

// swiftlint:enable discouraged_optional_collection
