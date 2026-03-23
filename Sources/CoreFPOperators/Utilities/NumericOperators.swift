import Foundation

// MARK: - Pattern Matching (Flipped)

/// Flipped pattern matching operator
/// Allows writing `value ≅ pattern` instead of `pattern ~= value`
///
/// Examples:
/// ```swift
/// statusCode ≅ 200...299           // true if statusCode in range
/// statusCode ≅ 250 ± 50            // true if statusCode in 200...300
/// temperature ≅ 20.0...25.0        // true if temperature in range
/// ```
public func ≅ <T>(_ value: T, _ pattern: ClosedRange<T>) -> Bool where T: Comparable {
    pattern ~= value
}

public func ≅ <T>(_ value: T, _ pattern: Range<T>) -> Bool where T: Comparable {
    pattern ~= value
}

public func ≅ <T>(_ value: T, _ pattern: PartialRangeFrom<T>) -> Bool where T: Comparable {
    pattern ~= value
}

public func ≅ <T>(_ value: T, _ pattern: PartialRangeThrough<T>) -> Bool where T: Comparable {
    pattern ~= value
}

public func ≅ <T>(_ value: T, _ pattern: PartialRangeUpTo<T>) -> Bool where T: Comparable {
    pattern ~= value
}

// MARK: - Plus-Minus Range

/// Plus-minus operator
/// Creates a symmetric closed range from a center value and delta
/// Delta is always treated as absolute value
///
/// Examples:
/// ```swift
/// 5.0 ± 0.5    // 4.5...5.5
/// 2 ± 5        // -3...7
/// 20 ± 3       // 17...23
/// 10 ± (-3)    // 7...13 (negative delta becomes positive)
/// ```
public func ± <T: SignedNumeric>(_ center: T, _ delta: T) -> ClosedRange<T> {
    let absDelta = abs(delta)
    return (center - absDelta)...(center + absDelta)
}

/// Plus-minus operator (alternative ASCII syntax)
/// Identical to ±
///
/// Examples:
/// ```swift
/// 5.0 +/- 0.5   // 4.5...5.5
/// 2 +/- 5       // -3...7
/// ```
public func +/- <T: SignedNumeric>(_ center: T, _ delta: T) -> ClosedRange<T> {
    let absDelta = abs(delta)
    return (center - absDelta)...(center + absDelta)
}
