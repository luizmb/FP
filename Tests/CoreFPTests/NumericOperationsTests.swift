// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Foundation
import Testing

@Suite struct NumericOperationsTests {
    // MARK: - symmetricRange

    @Test func symmetricRangeInteger() {
        let range = symmetricRange(5, delta: 2)
        #expect(range == 3...7)
        #expect(range.lowerBound == 3)
        #expect(range.upperBound == 7)
    }

    @Test func symmetricRangeDouble() {
        let range = symmetricRange(5.0, delta: 0.5)
        #expect(range == 4.5...5.5)
        #expect(range.contains(4.7))
        #expect(!range.contains(6.0))
    }

    @Test func symmetricRangeNegativeDelta() {
        // Negative delta treated as absolute value
        let range = symmetricRange(10, delta: -3)
        #expect(range == 7...13)
    }

    @Test func symmetricRangeZeroDelta() {
        let range = symmetricRange(10, delta: 0)
        #expect(range == 10...10)
        #expect(range.contains(10))
        #expect(!range.contains(9))
        #expect(!range.contains(11))
    }

    @Test func symmetricRangeDate() {
        // Strideable allows the same call shape for Date (Stride = TimeInterval).
        let now = Date(timeIntervalSince1970: 1_000_000)
        let range = symmetricRange(now, delta: 60.0)
        #expect(range.lowerBound == Date(timeIntervalSince1970: 999_940))
        #expect(range.upperBound == Date(timeIntervalSince1970: 1_000_060))
        #expect(range.contains(now))
    }

    // MARK: - rangeMatch

    @Test func rangeMatchClosedRange() {
        #expect(rangeMatch(200, in: 200...299) == true)
        #expect(rangeMatch(299, in: 200...299) == true)
        #expect(rangeMatch(300, in: 200...299) == false)
        #expect(rangeMatch(199, in: 200...299) == false)
    }

    @Test func rangeMatchHalfOpenRange() {
        #expect(rangeMatch(0, in: 0..<10) == true)
        #expect(rangeMatch(9, in: 0..<10) == true)
        #expect(rangeMatch(10, in: 0..<10) == false)
    }

    @Test func rangeMatchPartialRangeFrom() {
        #expect(rangeMatch(5, in: 5...) == true)
        #expect(rangeMatch(100, in: 5...) == true)
        #expect(rangeMatch(4, in: 5...) == false)
    }

    @Test func rangeMatchPartialRangeThrough() {
        #expect(rangeMatch(5, in: ...5) == true)
        #expect(rangeMatch(0, in: ...5) == true)
        #expect(rangeMatch(6, in: ...5) == false)
    }

    @Test func rangeMatchPartialRangeUpTo() {
        #expect(rangeMatch(4, in: ..<5) == true)
        #expect(rangeMatch(5, in: ..<5) == false)
    }

    @Test func rangeMatchWithSymmetricRange() {
        let range = symmetricRange(250, delta: 50)   // 200...300
        #expect(rangeMatch(250, in: range) == true)
        #expect(rangeMatch(200, in: range) == true)
        #expect(rangeMatch(300, in: range) == true)
        #expect(rangeMatch(199, in: range) == false)
        #expect(rangeMatch(301, in: range) == false)
    }

    // MARK: - power

    @Test func powerPositiveExponent() {
        #expect(power(2, 10) == 1_024)
        #expect(power(3, 3) == 27)
        #expect(power(5, 3) == 125)
    }

    @Test func powerZeroExponent() {
        #expect(power(2, 0) == 1)
        #expect(power(99, 0) == 1)
    }

    @Test func powerExponentOne() {
        #expect(power(7, 1) == 7)
        #expect(power(42, 1) == 42)
    }

    @Test func powerNegativeBase() {
        #expect(power(-2, 3) == -8)
        #expect(power(-3, 2) == 9)
    }
}
