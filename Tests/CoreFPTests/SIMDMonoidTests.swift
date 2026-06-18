// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

@Suite struct SIMDMonoidTests {
    // MARK: - Sum (Integer)

    @Test func intSum() {
        let a = SIMD4<Int>.Monoids.Sum(SIMD4(1, 2, 3, 4))
        let b = SIMD4<Int>.Monoids.Sum(SIMD4(10, 20, 30, 40))
        #expect(SIMD4<Int>.Monoids.Sum.combine(a, b).rawValue == SIMD4(11, 22, 33, 44))
        #expect(SIMD4<Int>.Monoids.Sum.identity.rawValue == SIMD4(0, 0, 0, 0))
        #expect(SIMD4<Int>.Monoids.Sum.combine(.identity, a) == a)
    }

    @Test func intSumWraps() {
        let a = SIMD2<UInt8>.Monoids.Sum(SIMD2(200, 100))
        let b = SIMD2<UInt8>.Monoids.Sum(SIMD2(100, 50))
        #expect(SIMD2<UInt8>.Monoids.Sum.combine(a, b).rawValue == SIMD2(44, 150))
    }

    // MARK: - Sum (FloatingPoint)

    @Test func floatSum() {
        let a = SIMD2<Float>.Monoids.Sum(SIMD2(1.5, 2.5))
        let b = SIMD2<Float>.Monoids.Sum(SIMD2(0.5, 0.5))
        #expect(SIMD2<Float>.Monoids.Sum.combine(a, b).rawValue == SIMD2(2.0, 3.0))
        #expect(SIMD2<Float>.Monoids.Sum.identity.rawValue == SIMD2(0.0, 0.0))
    }

    @Test func doubleSum() {
        let a = SIMD3<Double>.Monoids.Sum(SIMD3(1.0, 2.0, 3.0))
        let b = SIMD3<Double>.Monoids.Sum(SIMD3(4.0, 5.0, 6.0))
        #expect(SIMD3<Double>.Monoids.Sum.combine(a, b).rawValue == SIMD3(5.0, 7.0, 9.0))
        #expect(SIMD3<Double>.Monoids.Sum.identity.rawValue == SIMD3(0.0, 0.0, 0.0))
    }

    @Test func sumMconcat() {
        let values = [SIMD2(1, 2), SIMD2(3, 4), SIMD2(5, 6)].map { SIMD2<Int>.Monoids.Sum($0) }
        let total: SIMD2<Int>.Monoids.Sum = mconcat(values)
        let empty: SIMD2<Int>.Monoids.Sum = mconcat([])
        #expect(total.rawValue == SIMD2(9, 12))
        #expect(empty.rawValue == SIMD2(0, 0))
    }

    // MARK: - Product (Integer)

    @Test func intProduct() {
        let a = SIMD2<Int>.Monoids.Product(SIMD2(3, 5))
        let b = SIMD2<Int>.Monoids.Product(SIMD2(4, 2))
        #expect(SIMD2<Int>.Monoids.Product.combine(a, b).rawValue == SIMD2(12, 10))
        #expect(SIMD2<Int>.Monoids.Product.identity.rawValue == SIMD2(1, 1))
        #expect(SIMD2<Int>.Monoids.Product.combine(.identity, a) == a)
    }

    @Test func intProductWraps() {
        let a = SIMD2<UInt8>.Monoids.Product(SIMD2(50, 10))
        let b = SIMD2<UInt8>.Monoids.Product(SIMD2(10, 5))
        #expect(SIMD2<UInt8>.Monoids.Product.combine(a, b).rawValue == SIMD2(244, 50))
    }

    // MARK: - Product (FloatingPoint)

    @Test func floatProduct() {
        let a = SIMD2<Float>.Monoids.Product(SIMD2(2.0, 3.0))
        let b = SIMD2<Float>.Monoids.Product(SIMD2(3.0, 4.0))
        #expect(SIMD2<Float>.Monoids.Product.combine(a, b).rawValue == SIMD2(6.0, 12.0))
        #expect(SIMD2<Float>.Monoids.Product.identity.rawValue == SIMD2(1.0, 1.0))
    }

    @Test func productMconcat() {
        let values = [SIMD2(1, 2), SIMD2(3, 4), SIMD2(5, 6)].map { SIMD2<Int>.Monoids.Product($0) }
        let product: SIMD2<Int>.Monoids.Product = mconcat(values)
        let empty: SIMD2<Int>.Monoids.Product = mconcat([])
        #expect(product.rawValue == SIMD2(15, 48))
        #expect(empty.rawValue == SIMD2(1, 1))
    }

    // MARK: - RawRepresentable

    @Test func rawRepresentable() {
        #expect(SIMD2<Int>.Monoids.Sum(SIMD2(1, 2)).rawValue == SIMD2(1, 2))
        #expect(SIMD2<Int>.Monoids.Product(rawValue: SIMD2(3, 4))?.rawValue == SIMD2(3, 4))
    }

    // MARK: - Min

    @Test func intMin() {
        let a = SIMD4<Int>.Monoids.Min(SIMD4(5, 1, 8, 3))
        let b = SIMD4<Int>.Monoids.Min(SIMD4(2, 7, 4, 9))
        #expect(SIMD4<Int>.Monoids.Min.combine(a, b).rawValue == SIMD4(2, 1, 4, 3))
        #expect(SIMD4<Int>.Monoids.Min.identity.rawValue == SIMD4(repeating: .max))
        #expect(SIMD4<Int>.Monoids.Min.combine(.identity, a) == a)
    }

    @Test func floatMin() {
        let a = SIMD2<Float>.Monoids.Min(SIMD2(2.5, 1.0))
        let b = SIMD2<Float>.Monoids.Min(SIMD2(1.0, 3.0))
        #expect(SIMD2<Float>.Monoids.Min.combine(a, b).rawValue == SIMD2(1.0, 1.0))
    }

    @Test func minMconcat() {
        let values = [SIMD2(5, 9), SIMD2(1, 3), SIMD2(8, 2)].map { SIMD2<Int>.Monoids.Min($0) }
        let result: SIMD2<Int>.Monoids.Min = mconcat(values)
        let empty: SIMD2<Int>.Monoids.Min = mconcat([])
        #expect(result.rawValue == SIMD2(1, 2))
        #expect(empty.rawValue == SIMD2(repeating: .max))
    }

    // MARK: - Max

    @Test func intMax() {
        let a = SIMD4<Int>.Monoids.Max(SIMD4(5, 1, 8, 3))
        let b = SIMD4<Int>.Monoids.Max(SIMD4(2, 7, 4, 9))
        #expect(SIMD4<Int>.Monoids.Max.combine(a, b).rawValue == SIMD4(5, 7, 8, 9))
        #expect(SIMD4<Int>.Monoids.Max.identity.rawValue == SIMD4(repeating: .min))
        #expect(SIMD4<Int>.Monoids.Max.combine(.identity, a) == a)
    }

    @Test func floatMax() {
        let a = SIMD2<Float>.Monoids.Max(SIMD2(2.5, 1.0))
        let b = SIMD2<Float>.Monoids.Max(SIMD2(1.0, 3.0))
        #expect(SIMD2<Float>.Monoids.Max.combine(a, b).rawValue == SIMD2(2.5, 3.0))
    }

    @Test func maxMconcat() {
        let values = [SIMD2(5, 1), SIMD2(1, 9), SIMD2(8, 2)].map { SIMD2<Int>.Monoids.Max($0) }
        let result: SIMD2<Int>.Monoids.Max = mconcat(values)
        let empty: SIMD2<Int>.Monoids.Max = mconcat([])
        #expect(result.rawValue == SIMD2(8, 9))
        #expect(empty.rawValue == SIMD2(repeating: .min))
    }

    // MARK: - Other scalar types

    @Test func int32Sum() {
        let a = SIMD2<Int32>.Monoids.Sum(SIMD2(100, 200))
        let b = SIMD2<Int32>.Monoids.Sum(SIMD2(300, 400))
        #expect(SIMD2<Int32>.Monoids.Sum.combine(a, b).rawValue == SIMD2(400, 600))
    }

    @Test func uint64Product() {
        let a = SIMD2<UInt64>.Monoids.Product(SIMD2(3, 5))
        let b = SIMD2<UInt64>.Monoids.Product(SIMD2(4, 2))
        #expect(SIMD2<UInt64>.Monoids.Product.combine(a, b).rawValue == SIMD2(12, 10))
    }

    @Test func int8MinMax() {
        let a = SIMD2<Int8>.Monoids.Min(SIMD2(5, 3))
        let b = SIMD2<Int8>.Monoids.Min(SIMD2(3, 7))
        #expect(SIMD2<Int8>.Monoids.Min.combine(a, b).rawValue == SIMD2(3, 3))

        let c = SIMD2<Int8>.Monoids.Max(SIMD2(5, 3))
        let d = SIMD2<Int8>.Monoids.Max(SIMD2(3, 7))
        #expect(SIMD2<Int8>.Monoids.Max.combine(c, d).rawValue == SIMD2(5, 7))
    }

    // MARK: - Various SIMD sizes

    @Test func simd8Sum() {
        let a = SIMD8<Int>.Monoids.Sum(SIMD8(1, 2, 3, 4, 5, 6, 7, 8))
        let b = SIMD8<Int>.Monoids.Sum(SIMD8(repeating: 10))
        #expect(SIMD8<Int>.Monoids.Sum.combine(a, b).rawValue == SIMD8(11, 12, 13, 14, 15, 16, 17, 18))
    }

    @Test func simd16Product() {
        let a = SIMD16<Int>.Monoids.Product(SIMD16(repeating: 2))
        let b = SIMD16<Int>.Monoids.Product(SIMD16(repeating: 3))
        #expect(SIMD16<Int>.Monoids.Product.combine(a, b).rawValue == SIMD16(repeating: 6))
    }

    // MARK: - Literal syntax

    @Test func integerLiteral() {
        let sum: SIMD2<Int>.Monoids.Sum = 42
        #expect(sum.rawValue == SIMD2(42, 42))
    }

    @Test func floatLiteral() {
        let sum: SIMD2<Float>.Monoids.Sum = 3.14
        #expect(sum.rawValue == SIMD2(repeating: 3.14 as Float))
    }
}
