// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

@Suite struct BoolMonoidTests {
    // MARK: - And

    @Test func andCombine() {
        #expect(Bool.Monoids.And.combine(.init(true), .init(true)) == .init(true))
        #expect(Bool.Monoids.And.combine(.init(true), .init(false)) == .init(false))
        #expect(Bool.Monoids.And.combine(.init(false), .init(true)) == .init(false))
        #expect(Bool.Monoids.And.combine(.init(false), .init(false)) == .init(false))
    }

    @Test func andIdentity() {
        #expect(Bool.Monoids.And.identity == .init(true))
        #expect(Bool.Monoids.And.combine(.identity, .init(true)) == .init(true))
        #expect(Bool.Monoids.And.combine(.identity, .init(false)) == .init(false))
    }

    @Test func andMconcat() {
        let allTrue = mconcat([Bool.Monoids.And(true), .init(true), .init(true)])
        let withFalse = mconcat([Bool.Monoids.And(true), .init(false), .init(true)])
        let empty = mconcat([Bool.Monoids.And]())
        #expect(allTrue.rawValue == true)
        #expect(withFalse.rawValue == false)
        #expect(empty.rawValue == true)
    }

    // MARK: - Or

    @Test func orCombine() {
        #expect(Bool.Monoids.Or.combine(.init(true), .init(false)) == .init(true))
        #expect(Bool.Monoids.Or.combine(.init(false), .init(true)) == .init(true))
        #expect(Bool.Monoids.Or.combine(.init(false), .init(false)) == .init(false))
        #expect(Bool.Monoids.Or.combine(.init(true), .init(true)) == .init(true))
    }

    @Test func orIdentity() {
        #expect(Bool.Monoids.Or.identity == .init(false))
        #expect(Bool.Monoids.Or.combine(.identity, .init(false)) == .init(false))
        #expect(Bool.Monoids.Or.combine(.identity, .init(true)) == .init(true))
    }

    @Test func orMconcat() {
        let withTrue = mconcat([Bool.Monoids.Or(false), .init(false), .init(true)])
        let allFalse = mconcat([Bool.Monoids.Or(false), .init(false), .init(false)])
        let empty = mconcat([Bool.Monoids.Or]())
        #expect(withTrue.rawValue == true)
        #expect(allFalse.rawValue == false)
        #expect(empty.rawValue == false)
    }

    // MARK: - Xor

    @Test func xorCombine() {
        #expect(Bool.Monoids.Xor.combine(.init(true), .init(false)) == .init(true))
        #expect(Bool.Monoids.Xor.combine(.init(false), .init(true)) == .init(true))
        #expect(Bool.Monoids.Xor.combine(.init(true), .init(true)) == .init(false))
        #expect(Bool.Monoids.Xor.combine(.init(false), .init(false)) == .init(false))
    }

    @Test func xorIdentity() {
        #expect(Bool.Monoids.Xor.identity == .init(false))
        #expect(Bool.Monoids.Xor.combine(.identity, .init(true)) == .init(true))
        #expect(Bool.Monoids.Xor.combine(.identity, .init(false)) == .init(false))
    }

    @Test func xorMconcat() {
        let oddTrues = mconcat([Bool.Monoids.Xor(true), .init(false), .init(true)])
        let evenTrues = mconcat([Bool.Monoids.Xor(true), .init(true), .init(false)])
        let empty = mconcat([Bool.Monoids.Xor]())
        #expect(oddTrues.rawValue == false) // true XOR false XOR true = false
        #expect(evenTrues.rawValue == false) // true XOR true XOR false = false
        #expect(empty.rawValue == false) // identity
    }

    // MARK: - RawRepresentable

    @Test func rawRepresentable() {
        #expect(Bool.Monoids.And(true).rawValue == true)
        #expect(Bool.Monoids.Or(false).rawValue == false)
        #expect(Bool.Monoids.Xor(true).rawValue == true)
        #expect(Bool.Monoids.And(rawValue: true)?.rawValue == true)
    }
}
