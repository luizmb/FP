// SPDX-License-Identifier: Apache-2.0
/// Namespace for numeric ``Monoid`` instances.
///
/// `NumericMonoid<T>` provides four named newtypes for the common monoid structures
/// on numeric types. All four are `RawRepresentable` with `rawValue: T` and support
/// both integer and float literals for easy construction.
///
/// | Type | Operation | Identity | Constraint |
/// |------|-----------|---------|------------|
/// | `NumericMonoid<T>.Sum` | `+` | `0` | `Numeric` |
/// | `NumericMonoid<T>.Product` | `*` | `1` | `Numeric` |
/// | `NumericMonoid<T>.Min` | `min(_:_:)` | `T.max` | `Numeric & HasMax` |
/// | `NumericMonoid<T>.Max` | `max(_:_:)` | `T.min` | `Numeric & HasMin` |
///
/// All standard integer and floating-point types have a `Monoids` type alias:
/// `Int.Monoids`, `Double.Monoids`, `Float.Monoids`, etc.
///
/// ## Example
///
/// ```swift
/// // Sum a sequence of integers:
/// let total = mconcat([1, 2, 3, 4, 5].map(Int.Monoids.Sum.init))
/// total.rawValue   // 15
///
/// // Using <> (requires CoreFPOperators):
/// let product: Int.Monoids.Product = 2 <> 3 <> 4
/// product.rawValue  // 24
/// ```
///
/// Requires `ExpressibleByIntegerLiteral` (satisfied by all standard numeric types)
/// so that both 0 and 1 can be expressed as literals for identity elements.
///
/// - SeeAlso: ``Monoid``, ``mconcat(_:)``, ``SIMDMonoid``
public enum NumericMonoid<T: Numeric & ExpressibleByIntegerLiteral & Sendable> {
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

public protocol HasMax: Comparable, Sendable {
    static var max: Self { get }
}

public protocol HasMin: Comparable, Sendable {
    static var min: Self { get }
}

extension NumericMonoid where T: HasMax {
    /// Monoid under comparison, finding the minimum value, with identity Self.max.
    public struct Min: Monoid, RawRepresentable {
        public let rawValue: T

        public init(_ rawValue: T) {
            self.rawValue = rawValue
        }

        public init?(rawValue: T) {
            self.init(rawValue)
        }

        public static func combine(_ lhs: Min, _ rhs: Min) -> Min {
            Min(min(lhs.rawValue, rhs.rawValue))
        }

        public static var identity: Min { Min(.max) }
    }
}

extension NumericMonoid where T: HasMin {
    /// Monoid under comparison, finding the maximum value, with identity Self.min.
    public struct Max: Monoid, RawRepresentable {
        public let rawValue: T

        public init(_ rawValue: T) {
            self.rawValue = rawValue
        }

        public init?(rawValue: T) {
            self.init(rawValue)
        }

        public static func combine(_ lhs: Max, _ rhs: Max) -> Max {
            Max(max(lhs.rawValue, rhs.rawValue))
        }

        public static var identity: Max { Max(.min) }
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

extension NumericMonoid.Min: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: T.IntegerLiteralType) {
        self.init(T(integerLiteral: value))
    }
}

extension NumericMonoid.Max: ExpressibleByIntegerLiteral {
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

extension NumericMonoid.Min: ExpressibleByFloatLiteral where T: ExpressibleByFloatLiteral {
    public init(floatLiteral value: T.FloatLiteralType) {
        self.init(T(floatLiteral: value))
    }
}

extension NumericMonoid.Max: ExpressibleByFloatLiteral where T: ExpressibleByFloatLiteral {
    public init(floatLiteral value: T.FloatLiteralType) {
        self.init(T(floatLiteral: value))
    }
}

// MARK: - Numeric type aliases

extension Int: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<Int>
}

extension Int8: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<Int8>
}

extension Int16: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<Int16>
}

extension Int32: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<Int32>
}

extension Int64: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<Int64>
}

extension UInt: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<UInt>
}

extension UInt8: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<UInt8>
}

extension UInt16: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<UInt16>
}

extension UInt32: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<UInt32>
}

extension UInt64: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<UInt64>
}

extension Float: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<Float>

    public static var min: Float {
        -Float.greatestFiniteMagnitude
    }

    public static var max: Float {
        Float.greatestFiniteMagnitude
    }
}

extension Double: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<Double>

    public static var min: Double {
        -Double.greatestFiniteMagnitude
    }

    public static var max: Double {
        Double.greatestFiniteMagnitude
    }
}

// Float80 exists only on x86, and even there it is unavailable on Windows and Android
// (the Swift Android SDK marks it unavailable on the target platform regardless of arch).
#if arch(x86_64) && !os(Windows) && !os(Android)
extension Float80: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<Float80>

    public static var min: Float80 {
        -Float80.greatestFiniteMagnitude
    }

    public static var max: Float80 {
        Float80.greatestFiniteMagnitude
    }
}
#endif

#if canImport(CoreGraphics)
import CoreGraphics

extension CGFloat: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<CGFloat>

    public static var min: CGFloat {
        -CGFloat.greatestFiniteMagnitude
    }

    public static var max: CGFloat {
        CGFloat.greatestFiniteMagnitude
    }
}
#endif

#if canImport(Foundation)
import Foundation

extension Decimal: HasMax, HasMin {
    public typealias Monoids = NumericMonoid<Decimal>

    public static var min: Decimal {
        -Decimal.greatestFiniteMagnitude
    }

    public static var max: Decimal {
        Decimal.greatestFiniteMagnitude
    }
}
#endif
