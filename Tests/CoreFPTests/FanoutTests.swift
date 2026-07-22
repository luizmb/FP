// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

@Suite struct FanoutTests {
    private struct World: Sendable, Equatable {
        let badge: Int
        let save: Int
        let name: String
    }

    private struct Env: Sendable, Equatable {
        let badge: Int
        let save: Int
    }

    // MARK: - fanout(_:) — the tuple maker over functions

    @Test func fanoutFunctionsProducesTuple() {
        let lowest: @Sendable ([Int]) -> Int? = { $0.min() }
        let highest: @Sendable ([Int]) -> Int? = { $0.max() }
        let fn: @Sendable ([Int]) -> (Int?, Int?) = fanout(lowest, highest)
        let (min, max) = fn([9, 3, 5, 1, 16, 2])
        #expect(min == 1)
        #expect(max == 16)
    }

    @Test func fanoutAcceptsKeyPathLiteralsAsSendableFunctions() {
        // Key path literals convert to the `@Sendable (Root) -> Value` parameters — Option B, no symbols.
        let fn: @Sendable (World) -> (Int, Int) = fanout(\.badge, \.save)
        let (badge, save) = fn(World(badge: 7, save: 9, name: "x"))
        #expect(badge == 7)
        #expect(save == 9)
    }

    @Test func fanoutSingleFunction() {
        let fn: @Sendable (World) -> (String) = fanout(\.name)
        #expect(fn(World(badge: 0, save: 0, name: "solo")) == "solo")
    }

    // MARK: - fanout(keypaths:into:) — symbol-free fan-out into a multi-arg initializer

    @Test func fanoutKeypathsIntoInitializer() {
        let narrow: @Sendable (World) -> Env = fanout(keypaths: \.badge, \.save, into: Env.init)
        #expect(narrow(World(badge: 3, save: 4, name: "y")) == Env(badge: 3, save: 4))
    }

    @Test func fanoutKeypathsIntoArbitraryFunction() {
        let sum: @Sendable (Int, Int, Int) -> Int = { $0 + $1 + $2 }
        let total = fanout(keypaths: \World.badge, \World.save, \World.badge, into: sum)
        #expect(total(World(badge: 10, save: 5, name: "z")) == 25)
    }
}
