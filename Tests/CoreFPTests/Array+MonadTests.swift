@testable import CoreFP
import Testing

@Suite struct ArrayMonadTests {
    @Test func bind() {
        let array = [1, 2, 3]
        let result = Array.bind({ [$0, $0 * 2] })(array)
        #expect(result == [1, 2, 2, 4, 3, 6])
    }

    @Test func kleisliComposition() {
        let duplicate: (Int) -> [Int] = { [$0, $0] }
        let double: (Int) -> [Int] = { [$0 * 2] }

        let composed = Array.kleisli(duplicate, double)
        #expect(composed(5) == [10, 10])
    }

    @Test func alt() {
        let arr1 = [1, 2, 3]
        let arr2 = [4, 5, 6]

        #expect(Array.alt(arr1, arr2) == [1, 2, 3, 4, 5, 6])
    }

    @Test func concat() {
        let arrays = [[1, 2], [3, 4], [5, 6]]
        let result = Array.concat(arrays)
        #expect(result == [1, 2, 3, 4, 5, 6])
    }

    @Test func join() {
        let nested = [[1, 2], [3, 4], [5, 6]]
        let result = Array.join(nested)
        #expect(result == [1, 2, 3, 4, 5, 6])
    }

    @Test func monadLeftIdentityLaw() {
        // return a >>= f = f a
        let a = 5
        let f: (Int) -> [Int] = { [$0 * 2] }

        let left = [a].flatMap(f)
        let right = f(a)

        #expect(left == right)
    }

    @Test func monadRightIdentityLaw() {
        // m >>= return = m
        let m = [1, 2, 3]
        let pureFunc: (Int) -> [Int] = { [$0] }

        #expect(m.flatMap(pureFunc) == m)
    }

    @Test func monadAssociativityLaw() {
        // (m >>= f) >>= g = m >>= (\x -> f x >>= g)
        let m = [1, 2]
        let f: (Int) -> [Int] = { [$0, $0 + 1] }
        let g: (Int) -> [Int] = { [$0 * 2] }

        let left = m.flatMap(f).flatMap(g)
        let right = m.flatMap { x in f(x).flatMap(g) }

        #expect(left == right)
    }

    // MARK: - join / void

    @Test func joinFreeFunction() {
        let nested: [[Int]] = [[1, 2], [3], [4, 5]]
        #expect(CoreFP.join(nested) == [1, 2, 3, 4, 5])
    }

    @Test func joinEmpty() {
        let nested: [[Int]] = [[], [], []]
        #expect(CoreFP.join(nested) == [])
    }

    @Test func voidFreeFunction() {
        #expect(CoreFP.void([1, 2, 3]).count == 3)
    }

    @Test func voidEmpty() {
        #expect(CoreFP.void([Int]()).isEmpty)
    }
}
