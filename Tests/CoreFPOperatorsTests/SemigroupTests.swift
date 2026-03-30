@testable import CoreFP
@testable import CoreFPOperators
import Foundation
import Testing

@Suite struct SemigroupTests {
    @Test func arraySemigroup() {
        let arr1 = [1, 2, 3]
        let arr2 = [4, 5, 6]

        #expect((arr1 <> arr2) == [1, 2, 3, 4, 5, 6])
    }

    @Test func stringSemigroup() {
        #expect(("Hello, " <> "World!") == "Hello, World!")
    }

    @Test func setSemigroup() {
        let set1: Set<Int> = [1, 2, 3]
        let set2: Set<Int> = [3, 4, 5]

        #expect((set1 <> set2) == [1, 2, 3, 4, 5])
    }

    @Test func dictionarySemigroup() {
        let dict1 = ["a": 1, "b": 2]
        let dict2 = ["b": 3, "c": 4]

        let result = dict1 <> dict2
        #expect(result == ["a": 1, "b": 3, "c": 4])
    }

    @Test func semigroupAssociativity() {
        // (a <> b) <> c = a <> (b <> c)
        let a = [1, 2]
        let b = [3, 4]
        let c = [5, 6]

        let left = (a <> b) <> c
        let right = a <> (b <> c)

        #expect(left == right)
    }

    // MARK: - Optional (Semigroup when Wrapped: Semigroup)

    @Test func optionalSemigroup() {
        let some: String? = "hello"
        let none: String? = nil
        #expect((some <> none) == "hello")
        #expect((none <> some) == "hello")
        #expect((some <> .some(" world")) == "hello world")
        #expect((none <> none) == nil)
    }

    // MARK: - Bool.Monoids wrappers

    @Test func boolAndSemigroup() {
        #expect((Bool.Monoids.And(true) <> .init(false)) == .init(false))
        #expect((Bool.Monoids.And(true) <> .init(true)) == .init(true))
    }

    @Test func boolOrSemigroup() {
        #expect((Bool.Monoids.Or(false) <> .init(true)) == .init(true))
        #expect((Bool.Monoids.Or(false) <> .init(false)) == .init(false))
    }

    // MARK: - Numeric wrappers

    @Test func intSum() {
        #expect((Int.Monoids.Sum(3) <> .init(4)) == .init(7))
    }

    @Test func intProduct() {
        #expect((Int.Monoids.Product(3) <> .init(4)) == .init(12))
    }
}
