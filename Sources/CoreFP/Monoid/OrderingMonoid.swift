// SPDX-License-Identifier: Apache-2.0
import Foundation

/// A ``Monoid`` for lexicographic combination of comparison results.
///
/// Wraps `ComparisonResult` (`.orderedAscending`, `.orderedSame`, `.orderedDescending`).
/// `combine` implements short-circuiting lexicographic comparison: the first non-`.orderedSame`
/// operand wins; a tie falls through to the other operand. This is exactly the algebra behind
/// composite sort comparators — chain several per-key comparisons and let ``mconcat(_:)`` pick
/// the first one that actually discriminates between two values.
///
/// | Type | Operation | Identity |
/// |------|-----------|---------|
/// | `Ordering` | lexicographic short-circuit | `.orderedSame` |
///
/// ## Example
///
/// ```swift
/// struct Person { let lastName: String; let firstName: String; let age: Int }
///
/// let byLastName  = comparing { (p: Person) in p.lastName }
/// let byFirstName = comparing { (p: Person) in p.firstName }
/// let byAge       = comparing { (p: Person) in p.age }
///
/// let compare: (Person, Person) -> Ordering = { l, r in
///     mconcat([byLastName(l, r), byFirstName(l, r), byAge(l, r)])
/// }
///
/// people.sorted { compare($0, $1).rawValue == .orderedAscending }
/// ```
///
/// - SeeAlso: ``Monoid``, ``comparing(_:)``
public struct Ordering: Monoid, RawRepresentable {
    public let rawValue: ComparisonResult

    public init(_ rawValue: ComparisonResult) {
        self.rawValue = rawValue
    }

    public init?(rawValue: ComparisonResult) {
        self.init(rawValue)
    }

    /// Keeps `lhs` unless it is a tie (`.orderedSame`), in which case `rhs` decides.
    public static func combine(_ lhs: Ordering, _ rhs: Ordering) -> Ordering {
        lhs.rawValue != .orderedSame ? lhs : rhs
    }

    public static var identity: Ordering { Ordering(.orderedSame) }
}

/// Builds a comparator that produces an ``Ordering`` from a projected `Comparable` key.
///
/// Useful for composing multi-key sort comparators via ``mconcat(_:)``: build one comparator
/// per key with `comparing`, apply them all to the same pair, then `mconcat` the results — the
/// first comparator that discriminates between the two values wins, exactly like SQL's
/// `ORDER BY a, b, c`.
///
/// ```swift
/// let byAge = comparing { (p: Person) in p.age }
/// byAge(youngPerson, oldPerson)   // Ordering(.orderedAscending)
/// ```
///
/// - Parameter keyExtractor: Projects the comparison key out of each value.
/// - Returns: A `(T, T) -> Ordering` comparator over the projected key.
/// - SeeAlso: ``Ordering``
public func comparing<T, Value: Comparable>(
    _ keyExtractor: @escaping @Sendable (T) -> Value
) -> @Sendable (T, T) -> Ordering {
    { lhs, rhs in
        let left = keyExtractor(lhs)
        let right = keyExtractor(rhs)
        if left < right { return Ordering(.orderedAscending) }
        if left > right { return Ordering(.orderedDescending) }
        return Ordering(.orderedSame)
    }
}
