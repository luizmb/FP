// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

@Suite struct NumericMonoidTests {
    // MARK: - Sum

    @Test func intSum() {
        #expect(Int.Monoids.Sum.combine(3, 4) == 7)
        #expect(Int.Monoids.Sum.identity == 0)
        #expect(Int.Monoids.Sum.combine(.identity, 5) == 5)
    }

    @Test func doubleSum() {
        #expect(Double.Monoids.Sum.combine(1.5, 2.5) == 4.0)
        #expect(Double.Monoids.Sum.identity == 0.0)
    }

    @Test func sumMconcat() {
        let values = [1, 2, 3, 4, 5].map { Int.Monoids.Sum($0) }
        let total: Int.Monoids.Sum = mconcat(values)
        let empty: Int.Monoids.Sum = mconcat([])
        #expect(total.rawValue == 15)
        #expect(empty.rawValue == 0)
    }

    // MARK: - Product

    @Test func intProduct() {
        #expect(Int.Monoids.Product.combine(3, 4) == 12)
        #expect(Int.Monoids.Product.identity == 1)
        #expect(Int.Monoids.Product.combine(.identity, 5) == 5)
    }

    @Test func doubleProduct() {
        #expect(Double.Monoids.Product.combine(2.0, 3.0) == 6.0)
        #expect(Double.Monoids.Product.identity == 1.0)
    }

    @Test func productMconcat() {
        let values = [1, 2, 3, 4, 5].map { Int.Monoids.Product($0) }
        let product: Int.Monoids.Product = mconcat(values)
        let empty: Int.Monoids.Product = mconcat([])
        #expect(product.rawValue == 120)
        #expect(empty.rawValue == 1)
    }

    // MARK: - RawRepresentable

    @Test func rawRepresentable() {
        #expect(Int.Monoids.Sum(42).rawValue == 42)
        #expect(Int.Monoids.Product(rawValue: 7)?.rawValue == 7)
    }

    // MARK: - Min

    @Test func intMin() {
        #expect(Int.Monoids.Min.combine(7, 3) == 3)
        #expect(Int.Monoids.Min.combine(3, 7) == 3)
        #expect(Int.Monoids.Min.identity.rawValue == Int.max)
        #expect(Int.Monoids.Min.combine(.identity, 5) == 5)
    }

    @Test func doubleMin() {
        #expect(Double.Monoids.Min.combine(2.5, 1.1) == 1.1)
        #expect(Double.Monoids.Min.identity.rawValue == Double.greatestFiniteMagnitude)
    }

    @Test func minMconcat() {
        let values = [5, 1, 9, 3].map { Int.Monoids.Min($0) }
        let result: Int.Monoids.Min = mconcat(values)
        let empty: Int.Monoids.Min = mconcat([])
        #expect(result.rawValue == 1)
        #expect(empty.rawValue == Int.max)
    }

    // MARK: - Max

    @Test func intMax() {
        #expect(Int.Monoids.Max.combine(7, 3) == 7)
        #expect(Int.Monoids.Max.combine(3, 7) == 7)
        #expect(Int.Monoids.Max.identity.rawValue == Int.min)
        #expect(Int.Monoids.Max.combine(.identity, 5) == 5)
    }

    @Test func doubleMax() {
        #expect(Double.Monoids.Max.combine(2.5, 1.1) == 2.5)
        #expect(Double.Monoids.Max.identity.rawValue == -Double.greatestFiniteMagnitude)
    }

    @Test func maxMconcat() {
        let values = [5, 1, 9, 3].map { Int.Monoids.Max($0) }
        let result: Int.Monoids.Max = mconcat(values)
        let empty: Int.Monoids.Max = mconcat([])
        #expect(result.rawValue == 9)
        #expect(empty.rawValue == Int.min)
    }

    // MARK: - Other integer types

    @Test func int32Sum() {
        #expect(Int32.Monoids.Sum.combine(100, 200) == 300)
    }

    @Test func uint64Product() {
        #expect(UInt64.Monoids.Product.combine(3, 5) == 15)
    }

    @Test func int8MinMax() {
        #expect(Int8.Monoids.Min.combine(5, 3) == 3)
        #expect(Int8.Monoids.Max.combine(5, 3) == 5)
    }
}
