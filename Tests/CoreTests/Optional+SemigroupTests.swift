import Testing
@testable import Core

@Suite struct OptionalSemigroupTests {

    // MARK: - Semigroup

    @Test func combinesBothPresent() {
        let lhs: String? = "hello"
        let rhs: String? = " world"
        #expect(Optional.combine(lhs, rhs) == "hello world")
    }

    @Test func prefersLeftWhenRightAbsent() {
        let lhs: String? = "hello"
        let rhs: String? = nil
        #expect(Optional.combine(lhs, rhs) == "hello")
    }

    @Test func prefersRightWhenLeftAbsent() {
        let lhs: String? = nil
        let rhs: String? = "world"
        #expect(Optional.combine(lhs, rhs) == "world")
    }

    @Test func noneWhenBothAbsent() {
        let lhs: String? = nil
        let rhs: String? = nil
        #expect(Optional<String>.combine(lhs, rhs) == nil)
    }

    @Test func semigroupAssociativity() {
        let a: String? = "a"
        let b: String? = "b"
        let c: String? = "c"
        let lhs = Optional.combine(Optional.combine(a, b), c)
        let rhs = Optional.combine(a, Optional.combine(b, c))
        #expect(lhs == rhs)
    }

    // MARK: - Monoid

    @Test func identity() {
        #expect(Optional<String>.identity == nil)
        #expect(Optional.combine(Optional<String>.identity, "hello") == "hello")
        #expect(Optional.combine("hello", Optional<String>.identity) == "hello")
    }

    @Test func mconcatOptionals() {
        let values: [String?] = ["foo", nil, "bar"]
        let combined = mconcat(values)
        let empty = mconcat([String?]())
        #expect(combined == "foobar")
        #expect(empty == nil)
    }
}
