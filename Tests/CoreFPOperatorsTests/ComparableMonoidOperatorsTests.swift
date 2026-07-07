// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
@testable import CoreFPOperators
import Foundation
import Testing

@Suite struct ComparableMonoidOperatorsTests {
    @Test func minMaxSemigroup() {
        #expect((Min(7) <> Min(3)) == Min(3))
        #expect((Max(7) <> Max(3)) == Max(7))
    }

    @Test func firstLastSemigroup() {
        #expect((First("prod") <> First("staging")) == First("prod"))
        #expect((Last("prod") <> Last("staging")) == Last("staging"))
    }

    @Test func dualReversesOrder() {
        let result = Dual<String>("a") <> Dual<String>("b")
        #expect(result.rawValue == "ba")
    }

    @Test func orderingShortCircuits() {
        let result = Ordering(.orderedSame) <> Ordering(.orderedDescending)
        #expect(result.rawValue == .orderedDescending)
    }
}
