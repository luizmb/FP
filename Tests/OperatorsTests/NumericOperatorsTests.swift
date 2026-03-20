import Testing
@testable import Operators

@Suite struct NumericOperatorsTests {

    // MARK: - Plus-Minus Tests

    @Test func plusMinusInteger() {
        let range = 2 ± 5
        #expect(range == -3...7)
        #expect(range.lowerBound == -3)
        #expect(range.upperBound == 7)
    }

    @Test func plusMinusDouble() {
        let range = 5.0 ± 0.5
        #expect(range == 4.5...5.5)
        #expect(range.contains(4.7))
        #expect(!range.contains(6.0))
    }

    @Test func plusMinusNegativeDelta() {
        // Delta should work with negative values too (absolute value)
        let range = 10 ± (-3)
        #expect(range == 7...13)
    }

    @Test func plusMinusAlternativeSyntax() {
        let range1 = 5.0 ± 0.5
        let range2 = 5.0 +/- 0.5
        #expect(range1 == range2)
    }

    @Test func plusMinusZeroDelta() {
        let range = 10 ± 0
        #expect(range == 10...10)
        #expect(range.contains(10))
        #expect(!range.contains(9))
        #expect(!range.contains(11))
    }

    // MARK: - Pattern Matching Tests

    @Test func patternMatchingClosedRange() {
        let statusCode = 200
        #expect((200...299).contains(statusCode))
        #expect(!(300...399).contains(statusCode))
        #expect((200...300).contains(250))
        #expect(!(200...300).contains(350))
    }

    @Test func patternMatchingWithPlusMinus() {
        let statusCode = 250
        #expect((250 ± 50).contains(statusCode))   // 200...300
        #expect((250 ± 10).contains(statusCode))   // 240...260
        #expect(!(200 ± 10).contains(statusCode))  // 190...210

        let temperature = 22.5
        #expect((20.0 ± 5.0).contains(temperature))   // 15.0...25.0
        #expect(!(20.0 ± 1.0).contains(temperature))  // 19.0...21.0
    }

    @Test func patternMatchingRange() {
        #expect((0..<10).contains(5))
        #expect(!(0..<10).contains(10))
        #expect((0..<10).contains(9))
    }

    @Test func patternMatchingPartialRanges() {
        // PartialRangeFrom (5...)
        #expect((5...).contains(10))
        #expect((5...).contains(5))
        #expect(!(5...).contains(4))

        // PartialRangeThrough (...5)
        #expect((...5).contains(5))
        #expect((...5).contains(3))
        #expect(!(...5).contains(6))

        // PartialRangeUpTo (..<5)
        #expect((..<5).contains(4))
        #expect(!(..<5).contains(5))
        #expect((..<5).contains(0))
    }

    @Test func patternMatchingDoubleRange() {
        let value = 3.14
        #expect((3.0...4.0).contains(value))
        #expect(!(4.0...5.0).contains(value))
    }

    // MARK: - Operator Equivalence Tests

    @Test func operatorEquivalence() {
        // Verify ≅ is equivalent to .contains()
        let statusCode = 200
        let range = 200...299
        let viaOperator: Bool = statusCode ≅ range
        let viaContains = range.contains(statusCode)
        #expect(viaOperator == viaContains)
    }
}
