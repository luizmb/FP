import Testing
@testable import Core

@Suite struct MonoidConformanceTests {

    @Test func stringMonoid() {
        #expect(String.identity == "")
        #expect(String.combine(String.identity, "hello") == "hello")
        #expect(String.combine("hello", String.identity) == "hello")
    }

    @Test func arrayMonoid() {
        #expect([Int].identity == [])
        #expect([Int].combine([Int].identity, [1, 2]) == [1, 2])
        #expect([Int].combine([1, 2], [Int].identity) == [1, 2])
    }

    @Test func setMonoid() {
        #expect(Set<Int>.identity == [])
        #expect(Set<Int>.combine(Set<Int>.identity, [1, 2]) == [1, 2])
    }

    @Test func dictionaryMonoid() {
        #expect([String: Int].identity == [:])
        #expect([String: Int].combine([String: Int].identity, ["a": 1]) == ["a": 1])
    }

    @Test func foldWithMconcat() {
        let strings = mconcat(["foo", "bar", "baz"])
        let emptyString = mconcat([String]())
        let arrays = mconcat([[1, 2], [3], [4, 5]])
        #expect(strings == "foobarbaz")
        #expect(emptyString == "")
        #expect(arrays == [1, 2, 3, 4, 5])
    }

    @Test func foldWithSconcat() {
        let strings = sconcat("foo", ["bar", "baz"])
        let arrays = sconcat([1, 2], [[3], [4, 5]])
        #expect(strings == "foobarbaz")
        #expect(arrays == [1, 2, 3, 4, 5])
    }
}
