import Testing
@testable import FP
@testable import Operators

@Suite struct OptionalFunctorTests {

    // MARK: - Basic Functor Tests

    @Test func fmap() {
        let value: Int? = 5
        let result = value.map { $0 * 2 }
        #expect(result == 10)

        let none: Int? = nil
        let noneResult = none.map { $0 * 2 }
        #expect(noneResult == nil)
    }

    @Test func curriedFmap() {
        let double: (Int) -> Int = { $0 * 2 }
        let fmap = Optional<Int>.fmap(double)

        #expect(fmap(5) == 10)
        #expect(fmap(nil) == nil)
    }

    // MARK: - Functor Laws

    @Test func functorIdentityLaw() {
        // fmap id == id
        let value: Int? = 5
        let none: Int? = nil

        let identity: (Int) -> Int = { $0 }

        #expect(value.map(identity) == value)
        #expect(none.map(identity) == none)
    }

    @Test func functorCompositionLaw() {
        // fmap (g . f) == fmap g . fmap f
        let value: Int? = 5

        let f: (Int) -> Int = { $0 * 2 }
        let g: (Int) -> String = { "\($0)" }

        let composed = value.map(compose(f, g))
        let separate = value.map(f).map(g)

        #expect(composed == separate)
    }

    // MARK: - Functor Operators

    @Test func fmapOperator() {
        let value: Int? = 5
        let result = { $0 * 2 } <£> value
        #expect(result == 10)

        let none: Int? = nil
        let noneResult = { $0 * 2 } <£> none
        #expect(noneResult == nil)
    }

    @Test func mapReplaceOperator() {
        let value: Int? = 5
        let result = value £> 99
        #expect(result == 99)

        let none: Int? = nil
        let noneResult = none £> 99
        #expect(noneResult == nil)
    }

    @Test func mapReplaceFlippedOperator() {
        let value: Int? = 5
        let result = 42 <£ value
        #expect(result == 42)

        let none: Int? = nil
        let noneResult = 42 <£ none
        #expect(noneResult == nil)
    }

    @Test func flippedFmapOperator() {
        let value: Int? = 5
        let result = value <&> { $0 * 2 }
        #expect(result == 10)

        let none: Int? = nil
        let noneResult = none <&> { $0 * 2 }
        #expect(noneResult == nil)
    }
}
