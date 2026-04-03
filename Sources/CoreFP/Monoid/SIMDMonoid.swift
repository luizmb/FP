/// Protocol bridging SIMD arithmetic so that integer scalars use wrapping
/// operations (`&+`, `&*`) while floating-point scalars use regular (`+`, `*`).
public protocol SIMDMonoidScalar: SIMDScalar, Hashable, Codable, Comparable, ExpressibleByIntegerLiteral {
    static func simdAdd<V: SIMD>(_ a: V, _ b: V) -> V where V.Scalar == Self
    static func simdMultiply<V: SIMD>(_ a: V, _ b: V) -> V where V.Scalar == Self
    static var one: Self { get }
}

extension SIMDMonoidScalar where Self: FixedWidthInteger {
    public static func simdAdd<V: SIMD>(_ a: V, _ b: V) -> V where V.Scalar == Self { a &+ b }
    public static func simdMultiply<V: SIMD>(_ a: V, _ b: V) -> V where V.Scalar == Self { a &* b }
    public static var one: Self { 1 }
}

extension SIMDMonoidScalar where Self: FloatingPoint & ExpressibleByIntegerLiteral {
    public static func simdAdd<V: SIMD>(_ a: V, _ b: V) -> V where V.Scalar == Self { a + b }
    public static func simdMultiply<V: SIMD>(_ a: V, _ b: V) -> V where V.Scalar == Self { a * b }
    public static var one: Self { 1 }
}

// MARK: - SIMDMonoid namespace

/// Namespace for SIMD Monoid instances.
/// Mirrors `NumericMonoid` but operates element-wise on SIMD vectors.
/// Integer scalars benefit from wrapping arithmetic (`&+`, `&*`);
/// floating-point scalars use standard arithmetic (`+`, `*`).
public enum SIMDMonoid<T: SIMD> where T.Scalar: SIMDMonoidScalar {
    /// Monoid under element-wise addition, with identity vector of zeros.
    public struct Sum: Monoid, RawRepresentable {
        public let rawValue: T

        public init(_ rawValue: T) {
            self.rawValue = rawValue
        }

        public init?(rawValue: T) {
            self.init(rawValue)
        }

        public static func combine(_ lhs: Sum, _ rhs: Sum) -> Sum {
            Sum(T.Scalar.simdAdd(lhs.rawValue, rhs.rawValue))
        }

        public static var identity: Sum { Sum(T(repeating: 0)) }
    }

    /// Monoid under element-wise multiplication, with identity vector of ones.
    public struct Product: Monoid, RawRepresentable {
        public let rawValue: T

        public init(_ rawValue: T) {
            self.rawValue = rawValue
        }

        public init?(rawValue: T) {
            self.init(rawValue)
        }

        public static func combine(_ lhs: Product, _ rhs: Product) -> Product {
            Product(T.Scalar.simdMultiply(lhs.rawValue, rhs.rawValue))
        }

        public static var identity: Product { Product(T(repeating: .one)) }
    }
}

extension SIMDMonoid where T.Scalar: HasMax {
    /// Monoid under element-wise minimum, with identity vector of Scalar.max.
    public struct Min: Monoid, RawRepresentable {
        public let rawValue: T

        public init(_ rawValue: T) {
            self.rawValue = rawValue
        }

        public init?(rawValue: T) {
            self.init(rawValue)
        }

        public static func combine(_ lhs: Min, _ rhs: Min) -> Min {
            let mask = lhs.rawValue .< rhs.rawValue
            return Min(rhs.rawValue.replacing(with: lhs.rawValue, where: mask))
        }

        public static var identity: Min { Min(T(repeating: .max)) }
    }
}

extension SIMDMonoid where T.Scalar: HasMin {
    /// Monoid under element-wise maximum, with identity vector of Scalar.min.
    public struct Max: Monoid, RawRepresentable {
        public let rawValue: T

        public init(_ rawValue: T) {
            self.rawValue = rawValue
        }

        public init?(rawValue: T) {
            self.init(rawValue)
        }

        public static func combine(_ lhs: Max, _ rhs: Max) -> Max {
            let mask = lhs.rawValue .> rhs.rawValue
            return Max(rhs.rawValue.replacing(with: lhs.rawValue, where: mask))
        }

        public static var identity: Max { Max(T(repeating: .min)) }
    }
}

// MARK: - ExpressibleByIntegerLiteral (all scalar types)

extension SIMDMonoid.Sum: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: T.Scalar.IntegerLiteralType) {
        self.init(T(repeating: T.Scalar(integerLiteral: value)))
    }
}

extension SIMDMonoid.Product: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: T.Scalar.IntegerLiteralType) {
        self.init(T(repeating: T.Scalar(integerLiteral: value)))
    }
}

extension SIMDMonoid.Min: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: T.Scalar.IntegerLiteralType) {
        self.init(T(repeating: T.Scalar(integerLiteral: value)))
    }
}

extension SIMDMonoid.Max: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: T.Scalar.IntegerLiteralType) {
        self.init(T(repeating: T.Scalar(integerLiteral: value)))
    }
}

// MARK: - ExpressibleByFloatLiteral (Float, Double)

extension SIMDMonoid.Sum: ExpressibleByFloatLiteral where T.Scalar: ExpressibleByFloatLiteral {
    public init(floatLiteral value: T.Scalar.FloatLiteralType) {
        self.init(T(repeating: T.Scalar(floatLiteral: value)))
    }
}

extension SIMDMonoid.Product: ExpressibleByFloatLiteral where T.Scalar: ExpressibleByFloatLiteral {
    public init(floatLiteral value: T.Scalar.FloatLiteralType) {
        self.init(T(repeating: T.Scalar(floatLiteral: value)))
    }
}

extension SIMDMonoid.Min: ExpressibleByFloatLiteral where T.Scalar: ExpressibleByFloatLiteral {
    public init(floatLiteral value: T.Scalar.FloatLiteralType) {
        self.init(T(repeating: T.Scalar(floatLiteral: value)))
    }
}

extension SIMDMonoid.Max: ExpressibleByFloatLiteral where T.Scalar: ExpressibleByFloatLiteral {
    public init(floatLiteral value: T.Scalar.FloatLiteralType) {
        self.init(T(repeating: T.Scalar(floatLiteral: value)))
    }
}

// MARK: - SIMDMonoidScalar conformances

extension Int: SIMDMonoidScalar {}
extension Int8: SIMDMonoidScalar {}
extension Int16: SIMDMonoidScalar {}
extension Int32: SIMDMonoidScalar {}
extension Int64: SIMDMonoidScalar {}
extension UInt: SIMDMonoidScalar {}
extension UInt8: SIMDMonoidScalar {}
extension UInt16: SIMDMonoidScalar {}
extension UInt32: SIMDMonoidScalar {}
extension UInt64: SIMDMonoidScalar {}
extension Float: SIMDMonoidScalar {}
extension Double: SIMDMonoidScalar {}

// MARK: - SIMD Monoids type aliases

extension SIMD2 where Scalar: SIMDMonoidScalar {
    public typealias Monoids = SIMDMonoid<Self>
}

extension SIMD3 where Scalar: SIMDMonoidScalar {
    public typealias Monoids = SIMDMonoid<Self>
}

extension SIMD4 where Scalar: SIMDMonoidScalar {
    public typealias Monoids = SIMDMonoid<Self>
}

extension SIMD8 where Scalar: SIMDMonoidScalar {
    public typealias Monoids = SIMDMonoid<Self>
}

extension SIMD16 where Scalar: SIMDMonoidScalar {
    public typealias Monoids = SIMDMonoid<Self>
}

extension SIMD32 where Scalar: SIMDMonoidScalar {
    public typealias Monoids = SIMDMonoid<Self>
}

extension SIMD64 where Scalar: SIMDMonoidScalar {
    public typealias Monoids = SIMDMonoid<Self>
}
