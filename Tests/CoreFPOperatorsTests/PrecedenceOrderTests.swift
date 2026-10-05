// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import Testing

// Mixing operators from different library precedence groups must compile without parentheses.
// These used to fail with "adjacent operators are in unordered precedence groups".

@Suite("Operator precedence order")
struct PrecedenceOrderTests {
    private let inc: @Sendable (Int) -> Int = { $0 + 1 }
    private let dbl: @Sendable (Int) -> Int = { $0 * 2 }

    @Test func functorBindsTighterThanMonadBind() {
        #expect((inc <£> [1, 2] >>- { [$0, $0] }) == [2, 2, 3, 3])
    }

    @Test func compositionBindsTighterThanPipe() {
        #expect((1 |> inc >>> dbl) == 4)
    }

    @Test func applicationOperatorsSitBelowEverything() {
        #expect((inc <£> [1] |> { $0 + [9] }) == [2, 9])
        let count: @Sendable ([Int]) -> Int = get(\[Int].count)
        #expect((count <| [inc] <*> [1, 2]) == 2)
    }

    @Test func alternativeBetweenFunctorAndBind() {
        let none: [Int] = []
        #expect((inc <£> none <|> [5] >>- { [$0, $0] }) == [5, 5])
    }

    // Haskell fixities: ==, +, *, ??, && and || bind tighter than <|>, which binds tighter than >=> / >>-, which bind
    // tighter than <| and |>. The functor family (<£>, <*>, ...) stays unordered against == (Haskell rejects that mix).

    private let flag: @Sendable (Bool) -> Int = { $0 ? 1 : 0 }

    @Test func nilCoalescingBindsTighterThanAlternative() {
        let none: Int? = nil
        #expect((none <|> none ?? 5 <|> 7) == 5)
        #expect((none <|> none ?? none) == nil)
    }

    @Test func arithmeticBindsTighterThanAlternative() {
        #expect(([1] <|> [2] + [3]) == [1, 2, 3])
        #expect(([] <|> [2] + [3]) == [2, 3])
    }

    @Test func comparisonAndLogicBindTighterThanApplication() {
        let one = 1
        #expect((one == 1 |> flag) == 1)
        #expect((false || true && true |> flag) == 1)
        #expect((flag <| 1 + 1 == 2) == 1)
        #expect((inc <| 1 + 2 * 3) == 8)
        #expect((1 + 2 |> inc) == 4)
        #expect((nil ?? 3 |> inc) == 4)
    }

    @Test func comparisonAndLogicBindTighterThanBind() {
        let logic: [Bool] = [true, false] >>- { [$0 && true || false] }
        #expect(logic == [true, false])
        #expect(([3] >>- { [$0 + 1 * 2] }) == [5])
    }

    @Test func functorFamilyBindsLooserThanArithmetic() {
        #expect((inc <£> [1] + [2]) == [2, 3])
    }

    @Test func alternativeBindsTighterThanKleisli() {
        let f: @Sendable (Int) -> [Int] = { [$0] }
        let g: @Sendable (Int) -> [Int] = { [$0 + 1] }
        #expect(([1] <|> [2] >>- f >>- g) == [2, 3])
        #expect((f >=> g <| 1) == [2])
    }
}
