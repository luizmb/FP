import Testing
@testable import Core
@testable import CoreOperators

@Suite struct OptionalMonadTests {

    @Test func bind() {
        let value: Int? = 5
        let result = value >>- { x in x > 0 ? .some(x * 2) : .none }
        #expect(result == 10)

        let none: Int? = nil
        let noneResult = none >>- { x in .some(x * 2) }
        #expect(noneResult == nil)
    }

    @Test func flippedBind() {
        let double: (Int) -> Int? = { .some($0 * 2) }
        let result = double -<< 5
        #expect(result == 10)
    }

    @Test func kleisliComposition() {
        let safe: (Int) -> Int? = { $0 > 0 ? .some($0) : .none }
        let double: (Int) -> Int? = { .some($0 * 2) }

        let composed = safe >=> double
        #expect(composed(5) == 10)
        #expect(composed(-1) == nil)
    }

    @Test func flippedFmap() {
        let value: Int? = 5
        let result = value <&> { $0 * 2 }
        #expect(result == 10)
    }

    @Test func alternative() {
        let some: Int? = 5
        let none: Int? = nil

        #expect((some <|> 10) == 5)
        #expect((none <|> 10) == 10)
        #expect((none <|> nil) == nil)
    }

    @Test func join() {
        let nested: Int?? = .some(.some(5))
        #expect(Optional<Int>.join(nested) == 5)

        let nestedNone: Int?? = .some(.none)
        #expect(Optional<Int>.join(nestedNone) == nil)

        let outerNone: Int?? = .none
        #expect(Optional<Int>.join(outerNone) == nil)
    }

    @Test func filter() {
        let value: Int? = 5
        #expect(value.filter { $0 > 3 } == 5)
        #expect(value.filter { $0 > 10 } == nil)
    }
}
