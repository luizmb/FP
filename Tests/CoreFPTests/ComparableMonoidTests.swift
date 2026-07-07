// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Foundation
import Testing

@Suite struct ComparableMonoidTests {
    // MARK: - Min

    @Test func minCombine() {
        #expect(Min.combine(Min(7), Min(3)) == Min(3))
        #expect(Min.combine(Min(3), Min(7)) == Min(3))
        #expect(Min.combine(Min("banana"), Min("apple")) == Min("apple"))
    }

    @Test func minSconcat() {
        let result = sconcat(Min(5), [Min(1), Min(9), Min(3)])
        #expect(result.rawValue == 1)
    }

    // MARK: - Max

    @Test func maxCombine() {
        #expect(Max.combine(Max(7), Max(3)) == Max(7))
        #expect(Max.combine(Max(3), Max(7)) == Max(7))
        #expect(Max.combine(Max("banana"), Max("apple")) == Max("banana"))
    }

    @Test func maxSconcat() {
        let result = sconcat(Max(5), [Max(1), Max(9), Max(3)])
        #expect(result.rawValue == 9)
    }

    // MARK: - First

    @Test func firstCombine() {
        #expect(First.combine(First("prod"), First("staging")) == First("prod"))
    }

    @Test func firstSconcat() {
        let result = sconcat(First("prod"), [First("staging"), First("dev")])
        #expect(result.rawValue == "prod")
    }

    // MARK: - Last

    @Test func lastCombine() {
        #expect(Last.combine(Last("prod"), Last("staging")) == Last("staging"))
    }

    @Test func lastSconcat() {
        let result = sconcat(Last("prod"), [Last("staging"), Last("dev")])
        #expect(result.rawValue == "dev")
    }

    // MARK: - Dual

    @Test func dualCombineReversesNonCommutativeOperation() {
        let result = Dual<String>.combine(Dual("a"), Dual("b"))
        #expect(result.rawValue == "ba")
    }

    @Test func dualSconcatReversesOrder() {
        let result = sconcat(Dual("a"), [Dual("b"), Dual("c")])
        #expect(result.rawValue == "cba")
    }

    @Test func dualIdentityMatchesWrappedMonoid() {
        #expect(Dual<Int.Monoids.Sum>.identity.rawValue.rawValue == 0)
    }

    @Test func dualMconcatEmptyReturnsIdentity() {
        let empty: Dual<Int.Monoids.Sum> = mconcat([])
        #expect(empty.rawValue.rawValue == 0)
    }

    @Test func dualMconcatCommutativeMonoid() {
        let values = [1, 2, 3].map { Dual(Int.Monoids.Sum($0)) }
        let result: Dual<Int.Monoids.Sum> = mconcat(values)
        #expect(result.rawValue.rawValue == 6)
    }

    // MARK: - RawRepresentable

    @Test func rawRepresentable() {
        #expect(Min(rawValue: 5)?.rawValue == 5)
        #expect(Max(rawValue: 5)?.rawValue == 5)
        #expect(First(rawValue: "x")?.rawValue == "x")
        #expect(Last(rawValue: "x")?.rawValue == "x")
        #expect(Dual(rawValue: Int.Monoids.Sum(1))?.rawValue.rawValue == 1)
    }

    // MARK: - Ordering

    @Test func orderingCombineShortCircuits() {
        #expect(Ordering.combine(Ordering(.orderedAscending), Ordering(.orderedDescending)).rawValue == .orderedAscending)
        #expect(Ordering.combine(Ordering(.orderedSame), Ordering(.orderedDescending)).rawValue == .orderedDescending)
        #expect(Ordering.combine(Ordering(.orderedSame), Ordering(.orderedSame)).rawValue == .orderedSame)
    }

    @Test func orderingIdentity() {
        #expect(Ordering.identity.rawValue == .orderedSame)
        #expect(Ordering.combine(.identity, Ordering(.orderedAscending)).rawValue == .orderedAscending)
        #expect(Ordering.combine(Ordering(.orderedAscending), .identity).rawValue == .orderedAscending)
    }

    @Test func orderingMconcatPicksFirstDiscriminator() {
        let values = [Ordering(.orderedSame), Ordering(.orderedSame), Ordering(.orderedDescending), Ordering(.orderedAscending)]
        #expect(mconcat(values).rawValue == .orderedDescending)
    }

    @Test func orderingMconcatEmptyReturnsIdentity() {
        let empty: Ordering = mconcat([])
        #expect(empty.rawValue == .orderedSame)
    }

    @Test func orderingRawRepresentable() {
        #expect(Ordering(rawValue: .orderedAscending)?.rawValue == .orderedAscending)
    }

    // MARK: - comparing

    struct Person {
        let lastName: String
        let firstName: String
    }

    @Test func comparingBuildsComparatorFromKey() {
        let byLastName = comparing { (p: Person) in p.lastName }
        let alice = Person(lastName: "Smith", firstName: "Alice")
        let bob = Person(lastName: "Jones", firstName: "Bob")

        #expect(byLastName(alice, bob).rawValue == .orderedDescending)
        #expect(byLastName(bob, alice).rawValue == .orderedAscending)
        #expect(byLastName(alice, alice).rawValue == .orderedSame)
    }

    @Test func comparingComposesViaMconcat() {
        let byLastName = comparing { (p: Person) in p.lastName }
        let byFirstName = comparing { (p: Person) in p.firstName }
        let alice = Person(lastName: "Jones", firstName: "Alice")
        let aaron = Person(lastName: "Jones", firstName: "Aaron")

        let combined = mconcat([byLastName(alice, aaron), byFirstName(alice, aaron)])
        #expect(combined.rawValue == .orderedDescending) // same last name, "Alice" > "Aaron"
    }
}
