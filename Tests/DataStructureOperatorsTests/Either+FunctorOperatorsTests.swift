// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct EitherFunctorTests {
    // MARK: - Basic Functor Tests

    @Test func mapRight() {
        let right: Either<String, Int> = .right(5)
        let result = right.mapRight { $0 * 2 }
        #expect(result == .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = left.mapRight { $0 * 2 }
        #expect(leftResult == .left("error"))
    }

    @Test func mapLeft() {
        let left: Either<String, Int> = .left("error")
        let result = left.mapLeft { $0.uppercased() }
        #expect(result == .left("ERROR"))

        let right: Either<String, Int> = .right(5)
        let rightResult = right.mapLeft { $0.uppercased() }
        #expect(rightResult == .right(5))
    }

    @Test func bimap() {
        let right: Either<String, Int> = .right(5)
        let rightResult = right.bimap({ $0.uppercased() }, { $0 * 2 })
        #expect(rightResult == .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = left.bimap({ $0.uppercased() }, { $0 * 2 })
        #expect(leftResult == .left("ERROR"))
    }

    @Test func bimapCurried() {
        let transform = Either<String, Int>.bimap({ $0.uppercased() }, { $0 * 2 })
        #expect(transform(.right(5)) == .right(10))
        #expect(transform(.left("error")) == .left("ERROR"))
    }

    @Test func bimapPointFree() {
        let values: [Either<String, Int>] = [.right(3), .left("x"), .right(7)]
        let result = values.map(Either<String, Int>.bimap({ $0 + "!" }, { $0 * 10 }))
        #expect(result == [.right(30), .left("x!"), .right(70)])
    }

    // MARK: - Functor Laws

    @Test func functorIdentityLaw() {
        // fmap id == id
        let right: Either<String, Int> = .right(5)
        let left: Either<String, Int> = .left("error")

        #expect(right.mapRight(id) == right)
        #expect(left.mapRight(id) == left)
    }

    @Test func functorCompositionLaw() {
        // fmap (g . f) == fmap g . fmap f
        let value: Either<String, Int> = .right(5)

        let f: @Sendable (Int) -> Int = { $0 * 2 }
        let g: @Sendable (Int) -> String = { "\($0)" }

        let composed = value.mapRight(compose(f, g))
        let separate = value.mapRight(f).mapRight(g)

        #expect(composed == separate)
    }

    // MARK: - Functor Operators

    @Test func fmapOperator() {
        let value: Either<String, Int> = .right(5)
        let result = { $0 * 2 } <£> value
        #expect(result == .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = { $0 * 2 } <£> left
        #expect(leftResult == .left("error"))
    }

    @Test func mapReplaceOperator() {
        let value: Either<String, Int> = .right(5)
        let result = value £> 99
        #expect(result == .right(99))

        let left: Either<String, Int> = .left("error")
        let leftResult = left £> 99
        #expect(leftResult == .left("error"))
    }

    @Test func mapReplaceFlippedOperator() {
        let value: Either<String, Int> = .right(5)
        let result = 42 <£ value
        #expect(result == .right(42))

        let left: Either<String, Int> = .left("error")
        let leftResult = 42 <£ left
        #expect(leftResult == .left("error"))
    }

    @Test func flippedFmapOperator() {
        let value: Either<String, Int> = .right(5)
        let result = value <&> { $0 * 2 }
        #expect(result == .right(10))
    }
}
