/// Namespace for numeric Monoid instances.
/// Requires `ExpressibleByIntegerLiteral` (satisfied by all standard numeric types)
/// so that both 0 and 1 can be expressed as literals for identity elements.
public enum NumericMonoid<T: Numeric & ExpressibleByIntegerLiteral & Comparable> {
    /// Monoid under addition, with identity 0.
    public struct Sum: Monoid, RawRepresentable {
        public let rawValue: T

        public init(_ rawValue: T) {
            self.rawValue = rawValue
        }

        public init?(rawValue: T) {
            self.init(rawValue)
        }

        public static func combine(_ lhs: Sum, _ rhs: Sum) -> Sum {
            Sum(lhs.rawValue + rhs.rawValue)
        }

        public static var identity: Sum { Sum(.zero) }
    }

    /// Monoid under multiplication, with identity 1.
    public struct Product: Monoid, RawRepresentable {
        public let rawValue: T

        public init(_ rawValue: T) {
            self.rawValue = rawValue
        }

        public init?(rawValue: T) {
            self.init(rawValue)
        }

        public static func combine(_ lhs: Product, _ rhs: Product) -> Product {
            Product(lhs.rawValue * rhs.rawValue)
        }

        public static var identity: Product { Product(1) }
    }
}

// MARK: - ExpressibleByIntegerLiteral (all numeric types)

extension NumericMonoid.Sum: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: T.IntegerLiteralType) {
        self.init(T(integerLiteral: value))
    }
}

extension NumericMonoid.Product: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: T.IntegerLiteralType) {
        self.init(T(integerLiteral: value))
    }
}

// MARK: - ExpressibleByFloatLiteral (Float, Double, CGFloat)

extension NumericMonoid.Sum: ExpressibleByFloatLiteral where T: ExpressibleByFloatLiteral {
    public init(floatLiteral value: T.FloatLiteralType) {
        self.init(T(floatLiteral: value))
    }
}

extension NumericMonoid.Product: ExpressibleByFloatLiteral where T: ExpressibleByFloatLiteral {
    public init(floatLiteral value: T.FloatLiteralType) {
        self.init(T(floatLiteral: value))
    }
}

// MARK: - Numeric type aliases

extension Int {
    public typealias Monoids = NumericMonoid<Int>
}

extension Int8 {
    public typealias Monoids = NumericMonoid<Int8>
}

extension Int16 {
    public typealias Monoids = NumericMonoid<Int16>
}

extension Int32 {
    public typealias Monoids = NumericMonoid<Int32>
}

extension Int64 {
    public typealias Monoids = NumericMonoid<Int64>
}

extension UInt {
    public typealias Monoids = NumericMonoid<UInt>
}

extension UInt8 {
    public typealias Monoids = NumericMonoid<UInt8>
}

extension UInt16 {
    public typealias Monoids = NumericMonoid<UInt16>
}

extension UInt32 {
    public typealias Monoids = NumericMonoid<UInt32>
}

extension UInt64 {
    public typealias Monoids = NumericMonoid<UInt64>
}

extension Float {
    public typealias Monoids = NumericMonoid<Float>
}

extension Double {
    public typealias Monoids = NumericMonoid<Double>
}

#if canImport(CoreGraphics)
import CoreGraphics

extension CGFloat {
    public typealias Monoids = NumericMonoid<CGFloat>
}
#endif
