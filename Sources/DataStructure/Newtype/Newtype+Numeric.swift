// Numeric stack — all conformances delegate to RawValue. Operators like +, -, *, /, %, <<,
// >>, &, |, ^ come for free via these protocols, so this lives in DataStructure (not in
// DataStructureOperators) because they are native operators rather than custom symbols.

// MARK: - AdditiveArithmetic

extension Newtype: AdditiveArithmetic where RawValue: AdditiveArithmetic {
    public static var zero: Self { Self(.zero) }

    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(lhs.rawValue + rhs.rawValue)
    }

    public static func += (lhs: inout Self, rhs: Self) {
        lhs.rawValue += rhs.rawValue
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        Self(lhs.rawValue - rhs.rawValue)
    }

    public static func -= (lhs: inout Self, rhs: Self) {
        lhs.rawValue -= rhs.rawValue
    }
}

// MARK: - Numeric

extension Newtype: Numeric where RawValue: Numeric {
    public typealias Magnitude = RawValue.Magnitude

    public var magnitude: RawValue.Magnitude { rawValue.magnitude }

    public init?<T>(exactly source: T) where T: BinaryInteger {
        guard let raw = RawValue(exactly: source) else { return nil }
        self.init(raw)
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        Self(lhs.rawValue * rhs.rawValue)
    }

    public static func *= (lhs: inout Self, rhs: Self) {
        lhs.rawValue *= rhs.rawValue
    }
}

// MARK: - SignedNumeric

extension Newtype: SignedNumeric where RawValue: SignedNumeric {
    public static prefix func - (operand: Self) -> Self {
        Self(-operand.rawValue)
    }

    public mutating func negate() {
        rawValue.negate()
    }
}

// MARK: - Strideable

extension Newtype: Strideable where RawValue: Strideable {
    public typealias Stride = RawValue.Stride

    public func distance(to other: Self) -> RawValue.Stride {
        rawValue.distance(to: other.rawValue)
    }

    public func advanced(by n: RawValue.Stride) -> Self {
        Self(rawValue.advanced(by: n))
    }
}

// MARK: - BinaryInteger

extension Newtype: BinaryInteger where RawValue: BinaryInteger {
    public typealias Words = RawValue.Words

    public static var isSigned: Bool { RawValue.isSigned }

    public var words: RawValue.Words { rawValue.words }
    public var bitWidth: Int { rawValue.bitWidth }
    public var trailingZeroBitCount: Int { rawValue.trailingZeroBitCount }

    public init<T>(_ source: T) where T: BinaryFloatingPoint {
        self.init(RawValue(source))
    }

    public init<T>(_ source: T) where T: BinaryInteger {
        self.init(RawValue(source))
    }

    public init<T>(clamping source: T) where T: BinaryInteger {
        self.init(RawValue(clamping: source))
    }

    public init<T>(truncatingIfNeeded source: T) where T: BinaryInteger {
        self.init(RawValue(truncatingIfNeeded: source))
    }

    public init?<T>(exactly source: T) where T: BinaryFloatingPoint {
        guard let raw = RawValue(exactly: source) else { return nil }
        self.init(raw)
    }

    public static func / (lhs: Self, rhs: Self) -> Self {
        Self(lhs.rawValue / rhs.rawValue)
    }

    public static func /= (lhs: inout Self, rhs: Self) {
        lhs.rawValue /= rhs.rawValue
    }

    public static func % (lhs: Self, rhs: Self) -> Self {
        Self(lhs.rawValue % rhs.rawValue)
    }

    public static func %= (lhs: inout Self, rhs: Self) {
        lhs.rawValue %= rhs.rawValue
    }

    public static func & (lhs: Self, rhs: Self) -> Self {
        Self(lhs.rawValue & rhs.rawValue)
    }

    public static func &= (lhs: inout Self, rhs: Self) {
        lhs.rawValue &= rhs.rawValue
    }

    public static func | (lhs: Self, rhs: Self) -> Self {
        Self(lhs.rawValue | rhs.rawValue)
    }

    public static func |= (lhs: inout Self, rhs: Self) {
        lhs.rawValue |= rhs.rawValue
    }

    public static func ^ (lhs: Self, rhs: Self) -> Self {
        Self(lhs.rawValue ^ rhs.rawValue)
    }

    public static func ^= (lhs: inout Self, rhs: Self) {
        lhs.rawValue ^= rhs.rawValue
    }

    public static func << <RHS>(lhs: Self, rhs: RHS) -> Self where RHS: BinaryInteger {
        Self(lhs.rawValue << rhs)
    }

    public static func <<= <RHS>(lhs: inout Self, rhs: RHS) where RHS: BinaryInteger {
        lhs.rawValue <<= rhs
    }

    public static func >> <RHS>(lhs: Self, rhs: RHS) -> Self where RHS: BinaryInteger {
        Self(lhs.rawValue >> rhs)
    }

    public static func >>= <RHS>(lhs: inout Self, rhs: RHS) where RHS: BinaryInteger {
        lhs.rawValue >>= rhs
    }

    public static prefix func ~ (x: Self) -> Self {
        Self(~x.rawValue)
    }
}

// MARK: - FixedWidthInteger

extension Newtype: FixedWidthInteger where RawValue: FixedWidthInteger {
    public static var bitWidth: Int { RawValue.bitWidth }
    public static var max: Self { Self(RawValue.max) }
    public static var min: Self { Self(RawValue.min) }

    public var nonzeroBitCount: Int { rawValue.nonzeroBitCount }
    public var leadingZeroBitCount: Int { rawValue.leadingZeroBitCount }
    public var byteSwapped: Self { Self(rawValue.byteSwapped) }

    public init(_truncatingBits bits: UInt) {
        self.init(RawValue(_truncatingBits: bits))
    }

    public init(bigEndian value: Self) {
        self.init(RawValue(bigEndian: value.rawValue))
    }

    public init(littleEndian value: Self) {
        self.init(RawValue(littleEndian: value.rawValue))
    }

    public var bigEndian: Self { Self(rawValue.bigEndian) }
    public var littleEndian: Self { Self(rawValue.littleEndian) }

    public func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let r = rawValue.addingReportingOverflow(rhs.rawValue)
        return (Self(r.partialValue), r.overflow)
    }

    public func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let r = rawValue.subtractingReportingOverflow(rhs.rawValue)
        return (Self(r.partialValue), r.overflow)
    }

    public func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let r = rawValue.multipliedReportingOverflow(by: rhs.rawValue)
        return (Self(r.partialValue), r.overflow)
    }

    public func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let r = rawValue.dividedReportingOverflow(by: rhs.rawValue)
        return (Self(r.partialValue), r.overflow)
    }

    public func remainderReportingOverflow(dividingBy rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let r = rawValue.remainderReportingOverflow(dividingBy: rhs.rawValue)
        return (Self(r.partialValue), r.overflow)
    }

    public func multipliedFullWidth(by other: Self) -> (high: Self, low: RawValue.Magnitude) {
        let r = rawValue.multipliedFullWidth(by: other.rawValue)
        return (Self(r.high), r.low)
    }

    public func dividingFullWidth(_ dividend: (high: Self, low: RawValue.Magnitude)) -> (quotient: Self, remainder: Self) {
        let r = rawValue.dividingFullWidth((high: dividend.high.rawValue, low: dividend.low))
        return (Self(r.quotient), Self(r.remainder))
    }
}

// MARK: - UnsignedInteger / SignedInteger

extension Newtype: UnsignedInteger where RawValue: UnsignedInteger {}
extension Newtype: SignedInteger where RawValue: SignedInteger {}

// MARK: - LosslessStringConvertible
//
// Required by FixedWidthInteger. Note: when `RawValue == String` this `init?(_:)` overload
// coexists with the main `init(_ rawValue: RawValue)`. They differ by return type
// (Self vs Self?), so the call site disambiguates by the binding's annotation.

extension Newtype: LosslessStringConvertible where RawValue: LosslessStringConvertible {
    public init?(_ description: String) {
        guard let raw = RawValue(description) else { return nil }
        self.init(rawValue: raw)
    }
}

// MARK: - Floating-point operators (without FloatingPoint conformance)
//
// `FloatingPoint` itself can't be conformed to: its declaration requires
// `Magnitude == Self`, but the `Numeric` conformance above binds
// `Magnitude = RawValue.Magnitude`, and that binding is forced by signed integer types
// like `Int` (whose `Magnitude` is `UInt`, not `Int`). A single conformance can't satisfy
// both worlds — the same trade-off pointfree's `Tagged` made.
//
// What we *can* do is recover the floating-point operators users actually want — `/`,
// `/=`, `.squareRoot()`, etc. — as plain extension members. They behave identically to
// the FloatingPoint operators; you just can't pass the newtype to a generic
// `FloatingPoint` API. For that, project to `rawValue`.

extension Newtype where RawValue: FloatingPoint {
    public static func / (lhs: Self, rhs: Self) -> Self {
        Self(lhs.rawValue / rhs.rawValue)
    }

    public static func /= (lhs: inout Self, rhs: Self) {
        lhs.rawValue /= rhs.rawValue
    }

    public func squareRoot() -> Self {
        Self(rawValue.squareRoot())
    }

    public mutating func formSquareRoot() {
        rawValue.formSquareRoot()
    }

    public func remainder(dividingBy other: Self) -> Self {
        Self(rawValue.remainder(dividingBy: other.rawValue))
    }

    public func truncatingRemainder(dividingBy other: Self) -> Self {
        Self(rawValue.truncatingRemainder(dividingBy: other.rawValue))
    }

    public mutating func round(_ rule: FloatingPointRoundingRule = .toNearestOrEven) {
        rawValue.round(rule)
    }

    public func rounded(_ rule: FloatingPointRoundingRule = .toNearestOrEven) -> Self {
        Self(rawValue.rounded(rule))
    }

    public var isFinite: Bool { rawValue.isFinite }
    public var isInfinite: Bool { rawValue.isInfinite }
    public var isNaN: Bool { rawValue.isNaN }
    public var isZero: Bool { rawValue.isZero }
    public var sign: FloatingPointSign { rawValue.sign }
}
