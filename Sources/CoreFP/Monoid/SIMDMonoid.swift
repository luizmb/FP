/// A scalar type suitable for element-wise SIMD monoid operations.
///
/// This protocol bridges integer and floating-point SIMD scalars so that:
/// - Integer scalars use wrapping arithmetic (`&+`, `&*`) to avoid overflow traps.
/// - Floating-point scalars use regular arithmetic (`+`, `*`).
///
/// All standard SIMD scalar types (`Int`, `Int8`, `Int16`, `Int32`, `Int64`,
/// `UInt` and its variants, `Float`, `Double`) conform automatically.
///
/// - SeeAlso: ``SIMDMonoid``
public protocol SIMDMonoidScalar: SIMDScalar, Hashable, Codable, Comparable, ExpressibleByIntegerLiteral, Sendable {
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

/// Namespace for element-wise SIMD ``Monoid`` instances.
///
/// `SIMDMonoid<T>` mirrors ``NumericMonoid`` but operates on SIMD vector types.
/// Each nested struct is a ``Monoid`` that wraps a `T: SIMD` value and applies
/// the corresponding element-wise operation.
///
/// | Struct | Operation | Identity |
/// |--------|-----------|----------|
/// | `SIMDMonoid<T>.Sum` | Element-wise addition | Zero vector |
/// | `SIMDMonoid<T>.Product` | Element-wise multiplication | Ones vector |
/// | `SIMDMonoid<T>.Min` | Element-wise minimum | `Scalar.max` vector |
/// | `SIMDMonoid<T>.Max` | Element-wise maximum | `Scalar.min` vector |
///
/// All standard SIMD vector types (`SIMD2`, `SIMD3`, `SIMD4`, `SIMD8`, `SIMD16`,
/// `SIMD32`, `SIMD64`) gain a `Monoids` type alias pointing to `SIMDMonoid<Self>`.
///
/// ```swift
/// let a: SIMD4<Float>.Monoids.Sum = SIMD4<Float>.Monoids.Sum(SIMD4(1, 2, 3, 4))
/// let b: SIMD4<Float>.Monoids.Sum = SIMD4<Float>.Monoids.Sum(SIMD4(10, 20, 30, 40))
/// let combined = SIMD4<Float>.Monoids.Sum.combine(a, b)
/// combined.rawValue   // SIMD4(11, 22, 33, 44)
/// ```
///
/// - SeeAlso: ``NumericMonoid``, ``Monoid``
public enum SIMDMonoid<T: SIMD & Sendable> where T.Scalar: SIMDMonoidScalar {
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
