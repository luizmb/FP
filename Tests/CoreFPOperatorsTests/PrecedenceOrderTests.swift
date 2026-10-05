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
}
