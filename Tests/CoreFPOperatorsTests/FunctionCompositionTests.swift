@testable import CoreFP
@testable import CoreFPOperators
import Testing

@Suite struct FunctionCompositionTests {
    // MARK: - Composition Operators

    @Test func forwardComposition() {
        let addOne: (Int) -> Int = { $0 + 1 }
        let double: (Int) -> Int = { $0 * 2 }

        let composed = addOne >>> double
        #expect(composed(5) == 12) // (5 + 1) * 2 = 12
    }

    @Test func backwardComposition() {
        let addOne: (Int) -> Int = { $0 + 1 }
        let double: (Int) -> Int = { $0 * 2 }

        let composed = double <<< addOne
        #expect(composed(5) == 12) // (5 + 1) * 2 = 12
    }

    @Test func compositionAssociativity() {
        let f: (Int) -> Int = { $0 + 1 }
        let g: (Int) -> Int = { $0 * 2 }
        let h: (Int) -> Int = { $0 - 3 }

        let left = (f >>> g) >>> h
        let right = f >>> (g >>> h)

        #expect(left(5) == right(5))
    }

    // MARK: - Application Operators

    @Test func functionApplicationPound() {
        let addOne: (Int) -> Int = { $0 + 1 }

        #expect((addOne £ 5) == 6)
    }

    @Test func functionApplicationAngle() {
        let addOne: (Int) -> Int = { $0 + 1 }

        #expect((addOne <| 5) == 6)
    }

    @Test func flippedFunctionApplication() {
        let addOne: (Int) -> Int = { $0 + 1 }

        #expect((5 |> addOne) == 6)
    }

    @Test func pipeChaining() {
        let addOne: (Int) -> Int = { $0 + 1 }
        let double: (Int) -> Int = { $0 * 2 }
        let triple: (Int) -> Int = { $0 * 3 }

        let result = 5 |> addOne |> double |> triple
        #expect(result == 36) // ((5 + 1) * 2) * 3 = 36
    }

    @Test func functionApplicationVsComposition() {
        let addOne: (Int) -> Int = { $0 + 1 }
        let double: (Int) -> Int = { $0 * 2 }

        // Using composition
        let composed = addOne >>> double
        #expect(composed(5) == 12)

        // Using pipe
        let piped = 5 |> addOne |> double
        #expect(piped == 12)

        // They should be equivalent
        #expect(composed(5) == piped)
    }

    @Test func compositionIdentity() {
        let f: (Int) -> Int = { $0 * 2 }

        // f >>> id = f
        #expect((f >>> id)(5) == f(5))

        // id >>> f = f
        #expect((id >>> f)(5) == f(5))
    }
}
