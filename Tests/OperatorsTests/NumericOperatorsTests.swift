import XCTest
@testable import Operators

final class NumericOperatorsTests: XCTestCase {

    // MARK: - Plus-Minus Tests

    func testPlusMinusInteger() {
        let range = 2 ± 5
        XCTAssertEqual(range, -3...7)
        XCTAssertEqual(range.lowerBound, -3)
        XCTAssertEqual(range.upperBound, 7)
    }

    func testPlusMinusDouble() {
        let range = 5.0 ± 0.5
        XCTAssertEqual(range, 4.5...5.5)
        XCTAssertTrue(range.contains(4.7))
        XCTAssertFalse(range.contains(6.0))
    }

    func testPlusMinusNegativeDelta() {
        // Delta should work with negative values too (absolute value)
        let range = 10 ± (-3)
        XCTAssertEqual(range, 7...13)
    }

    func testPlusMinusAlternativeSyntax() {
        let range1 = 5.0 ± 0.5
        let range2 = 5.0 +/- 0.5
        XCTAssertEqual(range1, range2)
    }

    func testPlusMinusZeroDelta() {
        let range = 10 ± 0
        XCTAssertEqual(range, 10...10)
        XCTAssertTrue(range.contains(10))
        XCTAssertFalse(range.contains(9))
        XCTAssertFalse(range.contains(11))
    }

    // MARK: - Pattern Matching Tests

    func testPatternMatchingClosedRange() {
        let statusCode = 200
        XCTAssertTrue(statusCode ≅ 200...299)
        XCTAssertFalse(statusCode ≅ 300...399)
        XCTAssertTrue(250 ≅ 200...300)
        XCTAssertFalse(350 ≅ 200...300)
    }

    func testPatternMatchingWithPlusMinus() {
        let statusCode = 250
        XCTAssertTrue(statusCode ≅ 250 ± 50)  // 200...300
        XCTAssertTrue(statusCode ≅ 250 ± 10)  // 240...260
        XCTAssertFalse(statusCode ≅ 200 ± 10) // 190...210

        let temperature = 22.5
        XCTAssertTrue(temperature ≅ 20.0 ± 5.0)  // 15.0...25.0
        XCTAssertFalse(temperature ≅ 20.0 ± 1.0) // 19.0...21.0
    }

    func testPatternMatchingRange() {
        XCTAssertTrue(5 ≅ 0..<10)
        XCTAssertFalse(10 ≅ 0..<10)
        XCTAssertTrue(9 ≅ 0..<10)
    }

    func testPatternMatchingPartialRanges() {
        // PartialRangeFrom (5...)
        XCTAssertTrue(10 ≅ 5...)
        XCTAssertTrue(5 ≅ 5...)
        XCTAssertFalse(4 ≅ 5...)

        // PartialRangeThrough (...5)
        XCTAssertTrue(5 ≅ ...5)
        XCTAssertTrue(3 ≅ ...5)
        XCTAssertFalse(6 ≅ ...5)

        // PartialRangeUpTo (..<5)
        XCTAssertTrue(4 ≅ ..<5)
        XCTAssertFalse(5 ≅ ..<5)
        XCTAssertTrue(0 ≅ ..<5)
    }

    func testPatternMatchingDoubleRange() {
        let value = 3.14
        XCTAssertTrue(value ≅ 3.0...4.0)
        XCTAssertFalse(value ≅ 4.0...5.0)
    }
}
