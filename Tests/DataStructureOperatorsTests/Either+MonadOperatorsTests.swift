import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct EitherMonadTests {
    // MARK: - Basic Monad Tests

    @Test func flatMap() {
        let value: Either<String, Int> = .right(5)
        let result = value.flatMap { x in .right(x * 2) }
        #expect(result == .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = left.flatMap { x in .right(x * 2) }
        #expect(leftResult == .left("error"))

        let errorResult: Either<String, Int> = .right(5)
        let errorFlatMap = errorResult.flatMap { _ in Either<String, Int>.left("new error") }
        #expect(errorFlatMap == .left("new error"))
    }

    @Test func bind() {
        let transform: (Int) -> Either<String, Int> = { .right($0 * 2) }
        let value: Either<String, Int> = .right(5)
        let result = Either.bind(transform)(value)
        #expect(result == .right(10))
    }

    @Test func join() {
        // join is flatMap with id
        let nested: Either<String, Either<String, Int>> = .right(.right(5))
        let result = nested.flatMap(id)
        #expect(result == .right(5))

        let nestedLeft: Either<String, Either<String, Int>> = .right(.left("inner error"))
        let nestedLeftResult = nestedLeft.flatMap(id)
        #expect(nestedLeftResult == .left("inner error"))

        let outerLeft: Either<String, Either<String, Int>> = .left("outer error")
        let outerLeftResult = outerLeft.flatMap(id)
        #expect(outerLeftResult == .left("outer error"))
    }

    // MARK: - Monad Laws

    @Test func monadLeftIdentityLaw() {
        // return a >>= f == f a
        let a = 5
        let f: (Int) -> Either<String, Int> = { .right($0 * 2) }

        let left = Either<String, Int>.right(a).flatMap(f)
        let right = f(a)

        #expect(left == right)
    }

    @Test func monadRightIdentityLaw() {
        // m >>= return == m
        let m: Either<String, Int> = .right(5)
        let result = m.flatMap { Either<String, Int>.right($0) }

        #expect(result == m)

        let leftValue: Either<String, Int> = .left("error")
        let leftResult = leftValue.flatMap { Either<String, Int>.right($0) }
        #expect(leftResult == leftValue)
    }

    @Test func monadAssociativityLaw() {
        // (m >>= f) >>= g == m >>= (\x -> f x >>= g)
        let m: Either<String, Int> = .right(5)
        let f: (Int) -> Either<String, Int> = { .right($0 * 2) }
        let g: (Int) -> Either<String, Int> = { .right($0 + 10) }

        let left = m.flatMap(f).flatMap(g)
        let right = m.flatMap { x in f(x).flatMap(g) }

        #expect(left == right)
    }

    // MARK: - Kleisli Composition

    @Test func kleisliComposition() {
        let f: (Int) -> Either<String, Int> = { x in
            x > 0 ? .right(x * 2) : .left("negative")
        }
        let g: (Int) -> Either<String, String> = { .right("\($0)") }

        let composed = Either<String, Int>.kleisli(f, g)
        #expect(composed(5) == .right("10"))
        #expect(composed(-1) == .left("negative"))
    }

    @Test func kleisliBack() {
        let f: (Int) -> Either<String, Int> = { .right($0 * 2) }
        let g: (Int) -> Either<String, String> = { .right("\($0)") }

        let composed = Either<String, Int>.kleisliBack(g, f)
        #expect(composed(5) == .right("10"))
    }

    // MARK: - Monad Operators

    @Test func bindOperator() {
        let value: Either<String, Int> = .right(5)
        let result = value >>- { .right($0 * 2) }
        #expect(result == .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = left >>- { .right($0 * 2) }
        #expect(leftResult == .left("error"))
    }

    @Test func flippedBindOperator() {
        let transform: (Int) -> Either<String, Int> = { .right($0 * 2) }
        let value: Either<String, Int> = .right(5)
        let result = transform -<< value
        #expect(result == .right(10))
    }

    @Test func kleisliOperator() {
        let f: (Int) -> Either<String, Int> = { .right($0 * 2) }
        let g: (Int) -> Either<String, String> = { .right("\($0)") }

        let composed = f >=> g
        #expect(composed(5) == .right("10"))
    }

    @Test func kleisliBackFunction() {
        let f: (Int) -> Either<String, Int> = { .right($0 * 2) }
        let g: (Int) -> Either<String, String> = { .right("\($0)") }

        let composed = Either<String, Int>.kleisliBack(g, f)
        #expect(composed(5) == .right("10"))
    }

    // MARK: - Alternative

    @Test func alternative() {
        let right1: Either<String, Int> = .right(5)
        let right2: Either<String, Int> = .right(10)
        #expect((right1 <|> right2) == .right(5))

        let left: Either<String, Int> = .left("error")
        #expect((left <|> right2) == .right(10))

        let left2: Either<String, Int> = .left("error2")
        #expect((left <|> left2) == .left("error2"))
    }
}
