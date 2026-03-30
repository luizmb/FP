@testable import CoreFP
import Testing

@Suite struct NumericMonoidTests {
    // MARK: - Sum

    @Test func intSum() {
        #expect(Int.Monoids.Sum.combine(.init(3), .init(4)) == .init(7))
        #expect(Int.Monoids.Sum.identity == .init(0))
        #expect(Int.Monoids.Sum.combine(.identity, .init(5)) == .init(5))
    }

    @Test func doubleSum() {
        #expect(Double.Monoids.Sum.combine(.init(1.5), .init(2.5)) == .init(4.0))
        #expect(Double.Monoids.Sum.identity == .init(0.0))
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
        #expect(Int.Monoids.Product.combine(.init(3), .init(4)) == .init(12))
        #expect(Int.Monoids.Product.identity == .init(1))
        #expect(Int.Monoids.Product.combine(.identity, .init(5)) == .init(5))
    }

    @Test func doubleProduct() {
        #expect(Double.Monoids.Product.combine(.init(2.0), .init(3.0)) == .init(6.0))
        #expect(Double.Monoids.Product.identity == .init(1.0))
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

    // MARK: - Other integer types

    @Test func int32Sum() {
        #expect(Int32.Monoids.Sum.combine(.init(100), .init(200)) == .init(300))
    }

    @Test func uint64Product() {
        #expect(UInt64.Monoids.Product.combine(.init(3), .init(5)) == .init(15))
    }
}
