// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Foundation
import Testing

// Gen has no runner that creates the RNG; tests inject a seeded SplitMix64 explicitly.
private typealias G<V> = Gen<SplitMix64, V>

private extension Stateful where S == SplitMix64 {
    func value(seed: UInt64) -> A {
        var rng = SplitMix64(seed: seed)
        return run(&rng)
    }

    func values(seed: UInt64, count: Int) -> [A] {
        var rng = SplitMix64(seed: seed)
        return array(ofCount: count).run(&rng)
    }
}

@Suite("Gen")
struct GenTests {
    // MARK: - Reproducibility

    @Test func sameSeedSameValue() {
        let die = G.int(in: 1...6)
        let first = die.value(seed: 42)
        let second = die.value(seed: 42)
        #expect(first == second)
    }

    @Test func sameSeedSameSequence() {
        let die = G.int(in: 1...6)
        let first = die.values(seed: 7, count: 50)
        let second = die.values(seed: 7, count: 50)
        #expect(first == second)
    }

    @Test func differentSeedsDiffer() {
        // Two seeds producing identical 50-length int sequences would be astronomically unlikely.
        let die = G.int(in: 1...1_000_000)
        #expect(die.values(seed: 1, count: 50) != die.values(seed: 2, count: 50))
    }

    // MARK: - Bounds

    @Test func intStaysInRange() {
        let g = G.int(in: 10...20)
        #expect(g.values(seed: 99, count: 500).allSatisfy { (10...20).contains($0) })
    }

    @Test func doubleStaysInRange() {
        let g = G.double(in: -1.0...1.0)
        #expect(g.values(seed: 99, count: 500).allSatisfy { (-1.0...1.0).contains($0) })
    }

    // MARK: - Primitives access through the typealias

    @Test func boolPrimitive() {
        let values = Set(G.bool().values(seed: 3, count: 200))
        #expect(values == [true, false]) // both outcomes appear
    }

    @Test func uuidIsVersion4() {
        let uuids = G.uuid().values(seed: 5, count: 100)
        #expect(Set(uuids).count == 100) // all distinct
        for uuid in uuids {
            let v = uuid.uuid.6 & 0xF0
            let variant = uuid.uuid.8 & 0xC0
            #expect(v == 0x40) // version 4
            #expect(variant == 0x80) // RFC 4122 variant
        }
    }

    @Test func elementOfEmptyIsNil() {
        #expect(G.element(of: [Int]()).value(seed: 1) == nil)
    }

    @Test func elementOfNonEmptyIsMember() {
        let g = G.element(of: [10, 20, 30])
        #expect(g.values(seed: 1, count: 100).allSatisfy { $0.map([10, 20, 30].contains) ?? true })
    }

    // MARK: - Functor / Applicative / Monad (inherited from Stateful)

    @Test func mapTransforms() {
        let g = G.int(in: 0...9).map { $0 * 2 }
        #expect(g.values(seed: 1, count: 100).allSatisfy { $0.isMultiple(of: 2) && (0...18).contains($0) })
    }

    @Test func zipBuildsComposite() {
        struct Point: Equatable, Sendable { let x: Int; let y: Int }
        let g = G.zip(G.int(in: 0...5), G.int(in: 0...5)).map(Point.init)
        let p = g.value(seed: 1)
        #expect((0...5).contains(p.x) && (0...5).contains(p.y))
    }

    @Test func flatMapDependsOnPrior() {
        // First int chooses the array length; reproducible.
        let g = G.int(in: 1...3).flatMap { n in G.int(in: 0...9).array(ofCount: n) }
        let arr = g.value(seed: 1)
        #expect((1...3).contains(arr.count))
    }

    // MARK: - Combinators

    @Test func arrayOfFixedCount() {
        let g = G.int(in: 0...9).array(ofCount: 7)
        #expect(g.value(seed: 1).count == 7)
    }

    @Test func optionalProducesBoth() {
        let outcomes = G.int(in: 0...9).optional().values(seed: 4, count: 200)
        #expect(outcomes.contains(where: { $0 == nil }))
        #expect(outcomes.contains(where: { $0 != nil }))
    }

    @Test func oneOfPicksAChoice() {
        let g = G.one(of: NonEmpty(head: G.int(in: 0...0), tail: [G.int(in: 100...100)]))
        #expect(g.values(seed: 1, count: 100).allSatisfy { $0 == 0 || $0 == 100 })
    }

    @Test func frequencyHonorsWeights() {
        // Weight 10:1 in favor of 0 over 1 — expect far more 0s.
        let g = G.frequency(NonEmpty(head: (10, G.int(in: 0...0)), tail: [(1, G.int(in: 1...1))]))
        let zeros = g.values(seed: 1, count: 1_000).filter { $0 == 0 }.count
        #expect(zeros > 700) // overwhelmingly 0
    }

    @Test func stringFromLetters() {
        let g = G.string(of: .letter(), count: G.int(in: 5...5))
        let s = g.value(seed: 1)
        #expect(s.count == 5)
        // swiftlint:disable:next prefer_key_path
        #expect(s.allSatisfy { $0.isLetter })
    }
}
