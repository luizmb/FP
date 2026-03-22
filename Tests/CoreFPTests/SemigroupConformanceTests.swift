import Testing
@testable import CoreFP

@Suite struct SemigroupConformanceTests {

    @Test func stringSemigroup() {
        #expect(String.combine("Hello, ", "World!") == "Hello, World!")
    }

    @Test func arraySemigroup() {
        #expect([Int].combine([1, 2], [3, 4]) == [1, 2, 3, 4])
    }

    @Test func setSemigroup() {
        #expect(Set.combine([1, 2], [2, 3]) == [1, 2, 3])
    }

    @Test func dictionarySemigroup() {
        let result = [String: Int].combine(["a": 1, "b": 2], ["b": 99, "c": 3])
        #expect(result == ["a": 1, "b": 99, "c": 3])
    }

    @Test func semigroupAssociativity() {
        let a = "foo"
        let b = "bar"
        let c = "baz"
        #expect(String.combine(String.combine(a, b), c) == String.combine(a, String.combine(b, c)))
    }
}
