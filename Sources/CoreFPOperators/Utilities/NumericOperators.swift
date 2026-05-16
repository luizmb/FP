import CoreFP

// MARK: - Pattern Matching (Flipped)

/// Flipped pattern matching operator.
/// Allows writing `value ≅ range` instead of `range ~= value`.
///
/// ```swift
/// statusCode ≅ 200...299           // true if statusCode in range
/// statusCode ≅ 250 ± 50            // true if statusCode in 200...300
/// temperature ≅ 20.0...25.0        // true if temperature in range
/// ```
public func ≅ <T: Comparable>(_ value: T, _ range: ClosedRange<T>) -> Bool {
    rangeMatch(value, in: range)
}

public func ≅ <T: Comparable>(_ value: T, _ range: Range<T>) -> Bool {
    rangeMatch(value, in: range)
}

public func ≅ <T: Comparable>(_ value: T, _ range: PartialRangeFrom<T>) -> Bool {
    rangeMatch(value, in: range)
}

public func ≅ <T: Comparable>(_ value: T, _ range: PartialRangeThrough<T>) -> Bool {
    rangeMatch(value, in: range)
}

public func ≅ <T: Comparable>(_ value: T, _ range: PartialRangeUpTo<T>) -> Bool {
    rangeMatch(value, in: range)
}

// MARK: - Plus-Minus Range

/// Symmetric range operator — `center ± delta` → `ClosedRange`.
/// Delta is always treated as an absolute value.
///
/// `T` is constrained to `Strideable`, so this works for numeric types and also
/// for `Date` (delta is then a `TimeInterval`) and any other strideable type.
///
/// ```swift
/// 5.0 ± 0.5             // 4.5...5.5
/// 2 ± 5                 // -3...7
/// 20 ± 3                // 17...23
/// 10 ± (-3)             // 7...13 (negative delta becomes positive)
/// Date.now ± 60.0       // .now-60s ... .now+60s
/// ```
public func ± <T: Strideable>(_ center: T, _ delta: T.Stride) -> ClosedRange<T> {
    symmetricRange(center, delta: delta)
}

/// ASCII alias for `±`.
///
/// ```swift
/// 5.0 +/- 0.5   // 4.5...5.5
/// 2 +/- 5       // -3...7
/// ```
public func +/- <T: Strideable>(_ center: T, _ delta: T.Stride) -> ClosedRange<T> {
    symmetricRange(center, delta: delta)
}

// MARK: - Power
//
// Note: `^` cannot be defined for types conforming to `BinaryInteger` because
// Swift already defines `^` as bitwise XOR on those types, creating an
// irresolvable ambiguity. The operator is therefore limited to
// `BinaryFloatingPoint` types (Double, Float, Float16, etc.) which have no
// built-in `^`. For integer exponentiation use the named function `power(_:_:)`.

/// Raises a floating-point `base` to an integer `exp` using repeated multiplication.
///
/// ```swift
/// 2.0 ^ 10   // 1024.0
/// 3.0 ^ 3    // 27.0
/// 5.0 ^ 0    // 1.0
/// ```
public func ^ <T: BinaryFloatingPoint>(_ base: T, _ exp: Int) -> T {
    power(base, exp)
}
