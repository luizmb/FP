import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct StatefulTArrayOperatorsTests {
    @Test func fmap() {
        let s = Stateful<Int, [Int]>.pure([1, 2, 3])
        let result = { $0 * 2 } <£^> s
        #expect(result.eval(0) == [2, 4, 6])
    }

    @Test func flippedFmap() {
        let s = Stateful<Int, [Int]>.pure([1, 2, 3])
        let result = s <&^> { $0 * 2 }
        #expect(result.eval(0) == [2, 4, 6])
    }

    @Test func apply() {
        let sf = Stateful<Int, [@Sendable (Int) -> Int]>.pure([{ $0 + 1 }, { $0 * 10 }])
        let sa = Stateful<Int, [Int]>.pure([1, 2])
        let result = sf <*> sa
        #expect(result.eval(0) == [2, 3, 10, 20])
    }

    @Test func seqRight() {
        let lhs = Stateful<Int, [Int]>.pure([1, 2])
        let rhs = Stateful<Int, [String]>.pure(["a", "b"])
        let result = lhs *> rhs
        #expect(result.eval(0) == ["a", "b", "a", "b"])
    }

    @Test func seqLeft() {
        let lhs = Stateful<Int, [Int]>.pure([1, 2])
        let rhs = Stateful<Int, [String]>.pure(["a", "b"])
        let result = lhs <* rhs
        #expect(result.eval(0) == [1, 1, 2, 2])
    }

    @Test func bind() {
        let s = Stateful<Int, [Int]>.pure([1, 2, 3])
        let result = s >>- { n in Stateful<Int, [Int]>.pure([n, n * 10]) }
        #expect(result.eval(0) == [1, 10, 2, 20, 3, 30])
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> Stateful<Int, [Int]> = { n in .pure([n, n + 1]) }
        let g: @Sendable (Int) -> Stateful<Int, [String]> = { n in .pure(["\(n)"]) }
        let result = (f >=> g)(3)
        #expect(result.eval(0) == ["3", "4"])
    }
}
