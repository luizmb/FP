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

/// Raises `base` to the `exp` power using repeated multiplication.
/// Returns `1` for a zero exponent. Behaviour for negative exponents matches
/// repeated multiplication (integer truncation — use `Foundation.pow` for
/// fractional results).
///
/// ```swift
/// power(2, 10)   // 1024
/// power(3, 0)    // 1
/// power(5, 3)    // 125
/// ```
public func power<T: SignedNumeric>(_ base: T, _ exp: Int) -> T {
    guard exp > 0 else { return 1 }
    return (1..<exp).reduce(base) { acc, _ in acc * base }
}
