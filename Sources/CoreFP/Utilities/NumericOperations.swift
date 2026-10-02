// SPDX-License-Identifier: Apache-2.0

// MARK: - Symmetric Range

/// Builds a `ClosedRange` centred on `center` extending `delta` in both directions.
/// The delta is always treated as an absolute value, so negative deltas work correctly.
///
/// `T` is constrained to `Strideable`, so the same call works for numeric types
/// (`Int`, `Double`, `Float`, …) as well as for `Date` and any other strideable
/// custom type. `delta` is typed as `T.Stride`, so for `Date` you pass a
/// `TimeInterval`.
///
/// ```swift
/// symmetricRange(5, delta: 2)            // 3...7
/// symmetricRange(5.0, delta: 0.5)        // 4.5...5.5
/// symmetricRange(10, delta: -3)          // 7...13  (negative delta treated as positive)
/// symmetricRange(Date.now, delta: 60.0)  // .now-60s ... .now+60s
/// ```
public func symmetricRange<T: Strideable>(_ center: T, delta: T.Stride) -> ClosedRange<T> {
    let d = abs(delta)
    return center.advanced(by: -d) ... center.advanced(by: d)
}

// MARK: - Range Match (flipped)

/// Returns `true` when `value` falls inside `range`. Equivalent to `range ~= value`.
///
/// The argument order is flipped so the value comes first, making it natural in
/// operator position: `statusCode ≅ 200...299`.
///
/// ```swift
/// rangeMatch(200, in: 200...299)   // true
/// rangeMatch(300, in: 200...299)   // false
/// ```
public func rangeMatch<T: Comparable>(_ value: T, in range: ClosedRange<T>) -> Bool {
    range ~= value
}

/// Returns `true` when `value` falls inside the half-open `range`.
public func rangeMatch<T: Comparable>(_ value: T, in range: Range<T>) -> Bool {
    range ~= value
}

/// Returns `true` when `value` is at or above the lower bound.
public func rangeMatch<T: Comparable>(_ value: T, in range: PartialRangeFrom<T>) -> Bool {
    range ~= value
}

/// Returns `true` when `value` is at or below the upper bound.
public func rangeMatch<T: Comparable>(_ value: T, in range: PartialRangeThrough<T>) -> Bool {
    range ~= value
}

/// Returns `true` when `value` is strictly below the upper bound.
public func rangeMatch<T: Comparable>(_ value: T, in range: PartialRangeUpTo<T>) -> Bool {
    range ~= value
}

// MARK: - Integer Power

/// Raises `base` to a non-negative `exp` by squaring, O(log exp) multiplications.
/// Returns `1` for a zero exponent.
///
/// `SignedNumeric` has no division, so a negative exponent can't be expressed for
/// an arbitrary numeric type: this overload returns `1` for it. Integer and
/// floating-point bases pick the more specific overloads below, which handle
/// negative exponents properly.
///
/// ```swift
/// power(2, 10)   // 1024
/// power(3, 0)    // 1
/// power(5, 3)    // 125
/// ```
public func power<T: SignedNumeric>(_ base: T, _ exp: Int) -> T {
    exp > 0 ? powerBySquaring(base, exp) : 1
}

/// Raises an integer `base` to `exp`. A negative exponent follows integer division
/// truncation of `1 / base^|exp|`: `1` for a base of `1`, `±1` for a base of `-1`
/// (sign by parity) and `0` for any other base, including `0`.
///
/// ```swift
/// power(2, 10)    // 1024
/// power(2, -1)    // 0
/// power(-1, -3)   // -1
/// ```
public func power<T: SignedInteger>(_ base: T, _ exp: Int) -> T {
    guard exp < 0 else { return exp == 0 ? 1 : powerBySquaring(base, exp) }
    switch base {
    case 1:
        return 1

    case -1:
        return exp.isMultiple(of: 2) ? 1 : -1

    default:
        return 0
    }
}

/// Raises a floating-point `base` to an integer `exp`. A negative exponent yields
/// the reciprocal, `1 / base^|exp|`.
///
/// ```swift
/// power(2.0, 10)   // 1024.0
/// power(2.0, -1)   // 0.5
/// power(0.0, -1)   // +infinity
/// ```
public func power<T: FloatingPoint>(_ base: T, _ exp: Int) -> T {
    guard exp < 0 else { return exp == 0 ? 1 : powerBySquaring(base, exp) }
    return 1 / powerBySquaring(base, exp.magnitude)
}

/// `base^exp` for `exp > 0`, by repeated squaring.
private func powerBySquaring<T: Numeric, E: BinaryInteger>(_ base: T, _ exp: E) -> T {
    var result: T = 1
    var factor = base
    var remaining = exp
    while remaining > 0 {
        if remaining & 1 == 1 { result *= factor }
        remaining >>= 1
        if remaining > 0 { factor *= factor }
    }
    return result
}
