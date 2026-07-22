// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
@testable import CoreFPOperators
import Testing

@Suite struct FunctionCompositionTests {
    // MARK: - Composition Operators

    @Test func forwardComposition() {
        let addOne: @Sendable (Int) -> Int = { $0 + 1 }
        let double: @Sendable (Int) -> Int = { $0 * 2 }

        let composed = addOne >>> double
        #expect(composed(5) == 12) // (5 + 1) * 2 = 12
    }

    @Test func backwardComposition() {
        let addOne: @Sendable (Int) -> Int = { $0 + 1 }
        let double: @Sendable (Int) -> Int = { $0 * 2 }

        let composed = double <<< addOne
        #expect(composed(5) == 12) // (5 + 1) * 2 = 12
    }

    @Test func compositionAssociativity() {
        let f: @Sendable (Int) -> Int = { $0 + 1 }
        let g: @Sendable (Int) -> Int = { $0 * 2 }
        let h: @Sendable (Int) -> Int = { $0 - 3 }

        let left = (f >>> g) >>> h
        let right = f >>> (g >>> h)

        #expect(left(5) == right(5))
    }

    // MARK: - Application Operators

    @Test func functionApplicationPound() {
        let addOne: @Sendable (Int) -> Int = { $0 + 1 }

        #expect((addOne £ 5) == 6)
    }

    @Test func functionApplicationAngle() {
        let addOne: @Sendable (Int) -> Int = { $0 + 1 }

        #expect((addOne <| 5) == 6)
    }

    @Test func flippedFunctionApplication() {
        let addOne: @Sendable (Int) -> Int = { $0 + 1 }

        #expect((5 |> addOne) == 6)
    }

    @Test func pipeChaining() {
        let addOne: @Sendable (Int) -> Int = { $0 + 1 }
        let double: @Sendable (Int) -> Int = { $0 * 2 }
        let triple: @Sendable (Int) -> Int = { $0 * 3 }

        let result = 5 |> addOne |> double |> triple
        #expect(result == 36) // ((5 + 1) * 2) * 3 = 36
    }

    @Test func functionApplicationVsComposition() {
        let addOne: @Sendable (Int) -> Int = { $0 + 1 }
        let double: @Sendable (Int) -> Int = { $0 * 2 }

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
        let f: @Sendable (Int) -> Int = { $0 * 2 }

        // f >>> id = f
        #expect((f >>> id)(5) == f(5))

        // id >>> f = f
        #expect((id >>> f)(5) == f(5))
    }

    // MARK: - Variadic (fan-out) Composition

    private struct World: Sendable { let badge: Int; let save: Int }
    private struct Env: Sendable, Equatable {
        let badge: Int
        let save: Int
    }

    @Test func forwardFanoutComposition() {
        // `fanout` (tuple-producing) >>> a multi-argument initializer — bridges SE-0110.
        let narrow: @Sendable (World) -> Env = fanout(\.badge, \.save) >>> Env.init
        #expect(narrow(World(badge: 3, save: 4)) == Env(badge: 3, save: 4))
    }

    @Test func backwardFanoutComposition() {
        // Mirror: `make <<< fanout` equals `fanout >>> make`.
        let narrow: @Sendable (World) -> Env = Env.init <<< fanout(\.badge, \.save)
        #expect(narrow(World(badge: 5, save: 6)) == Env(badge: 5, save: 6))
    }

    @Test func variadicOverloadDoesNotBreakSingleArg() {
        // The single-argument `>>>` still resolves with the variadic overload in scope.
        let addOne: @Sendable (Int) -> Int = { $0 + 1 }
        let double: @Sendable (Int) -> Int = { $0 * 2 }
        #expect((addOne >>> double)(5) == 12)
    }
}
