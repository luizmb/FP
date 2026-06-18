// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Foundation
import Testing

@Suite("Gen")
struct GenTests {
    // MARK: - Reproducibility

    @Test func sameSeedSameValue() {
        let die = Gen.int(in: 1...6)
        let first = die.generate(seed: 42)
        let second = die.generate(seed: 42)
        #expect(first == second)
    }

    @Test func sameSeedSameSequence() {
        let die = Gen.int(in: 1...6)
        let first = die.samples(seed: 7, count: 50)
        let second = die.samples(seed: 7, count: 50)
        #expect(first == second)
    }

    @Test func differentSeedsDiffer() {
        // Two seeds producing identical 50-length int sequences would be astronomically unlikely.
        let die = Gen.int(in: 1...1_000_000)
        #expect(die.samples(seed: 1, count: 50) != die.samples(seed: 2, count: 50))
    }

    // MARK: - Bounds

    @Test func intStaysInRange() {
        let g = Gen.int(in: 10...20)
        #expect(g.samples(seed: 99, count: 500).allSatisfy { (10...20).contains($0) })
    }

    @Test func doubleStaysInRange() {
        let g = Gen.double(in: -1.0...1.0)
        #expect(g.samples(seed: 99, count: 500).allSatisfy { (-1.0...1.0).contains($0) })
    }

    // MARK: - Primitives access through the typealias

    @Test func boolPrimitive() {
        let values = Set(Gen.bool().samples(seed: 3, count: 200))
        #expect(values == [true, false]) // both outcomes appear
    }

    @Test func uuidIsVersion4() {
        let uuids = Gen.uuid().samples(seed: 5, count: 100)
        #expect(Set(uuids).count == 100) // all distinct
        for uuid in uuids {
            let v = uuid.uuid.6 & 0xF0
            let variant = uuid.uuid.8 & 0xC0
            #expect(v == 0x40)      // version 4
            #expect(variant == 0x80) // RFC 4122 variant
        }
    }

    @Test func elementOfEmptyIsNil() {
        #expect(Gen.element(of: [Int]()).generate(seed: 1) == nil)
    }

    @Test func elementOfNonEmptyIsMember() {
        let g = Gen.element(of: [10, 20, 30])
        #expect(g.samples(seed: 1, count: 100).allSatisfy { $0.map([10, 20, 30].contains) ?? true })
    }

    // MARK: - Functor / Applicative / Monad (inherited from Stateful)

    @Test func mapTransforms() {
        let g = Gen.int(in: 0...9).map { $0 * 2 }
        #expect(g.samples(seed: 1, count: 100).allSatisfy { $0.isMultiple(of: 2) && (0...18).contains($0) })
    }

    @Test func zipBuildsComposite() {
        struct Point: Equatable, Sendable { let x: Int; let y: Int }
        let g = Gen.zip(Gen.int(in: 0...5), Gen.int(in: 0...5)).map(Point.init)
        let p = g.generate(seed: 1)
        #expect((0...5).contains(p.x) && (0...5).contains(p.y))
    }

    @Test func flatMapDependsOnPrior() {
        // First int chooses the array length; reproducible.
        let g = Gen.int(in: 1...3).flatMap { n in Gen.int(in: 0...9).array(ofCount: n) }
        let arr = g.generate(seed: 1)
        #expect((1...3).contains(arr.count))
    }

    // MARK: - Combinators

    @Test func arrayOfFixedCount() {
        let g = Gen.int(in: 0...9).array(ofCount: 7)
        #expect(g.generate(seed: 1).count == 7)
    }

    @Test func optionalProducesBoth() {
        let outcomes = Gen.int(in: 0...9).optional().samples(seed: 4, count: 200)
        #expect(outcomes.contains(where: { $0 == nil }))
        #expect(outcomes.contains(where: { $0 != nil }))
    }

    @Test func oneOfPicksAChoice() {
        let g = Gen.one(of: NonEmpty(head: Gen.int(in: 0...0), tail: [Gen.int(in: 100...100)]))
        #expect(g.samples(seed: 1, count: 100).allSatisfy { $0 == 0 || $0 == 100 })
    }

    @Test func frequencyHonorsWeights() {
        // Weight 10:1 in favor of 0 over 1 — expect far more 0s.
        let g = Gen.frequency(NonEmpty(head: (10, Gen.int(in: 0...0)), tail: [(1, Gen.int(in: 1...1))]))
        let zeros = g.samples(seed: 1, count: 1_000).filter { $0 == 0 }.count
        #expect(zeros > 700) // overwhelmingly 0
    }

    @Test func stringFromLetters() {
        let g = Gen.string(of: .letter(), count: Gen.int(in: 5...5))
        let s = g.generate(seed: 1)
        #expect(s.count == 5)
        // swiftlint:disable:next prefer_key_path
        #expect(s.allSatisfy { $0.isLetter })
    }
}
