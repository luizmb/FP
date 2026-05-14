/// A type with a single associative binary operation.
///
/// A `Semigroup` provides one static operation, ``combine(_:_:)``, that satisfies
/// associativity:
///
/// ```
/// combine(combine(a, b), c) == combine(a, combine(b, c))   // associativity
/// ```
///
/// ## Standard conformances
///
/// The library provides `Semigroup` conformances for the following types:
///
/// | Type | Operation |
/// |------|-----------|
/// | `[A]` | Array concatenation |
/// | `Set<A>` | Set union |
/// | `Dictionary<K, V>` | Merge (right-biased) |
/// | `String` | String concatenation |
/// | `Optional<A: Semigroup>` | Lift `combine` into the optional context |
/// | ``Endo``<A> | Left-to-right composition |
/// | ``EndoMut``<A> | Sequential in-place application |
/// | ``Iso``<A, A> | Left-to-right composition (also a ``Monoid``) |
/// | `Bool.Monoids.And` | Logical conjunction |
/// | `Bool.Monoids.Or` | Logical disjunction |
/// | `Bool.Monoids.Xor` | Logical exclusive disjunction |
/// | `NumericMonoid<T>.Sum` | Numeric addition |
/// | `NumericMonoid<T>.Product` | Numeric multiplication |
///
/// ## Using the `<>` operator
///
/// Import `CoreFPOperators` to use the `<>` infix operator:
///
/// ```swift
/// [1, 2] <> [3, 4]           // [1, 2, 3, 4]
/// "hello" <> " world"        // "hello world"
/// Endo { $0 + 1 } <> Endo { $0 * 2 }  // applies +1 first, then *2
/// ```
///
/// - SeeAlso: ``Monoid``, ``sconcat(_:_:)``, ``mconcat(_:)``
public protocol Semigroup {
    /// Combines two values using the associative operation.
    ///
    /// The operation must satisfy associativity:
    /// `combine(combine(a, b), c) == combine(a, combine(b, c))`
    static func combine(_ lhs: Self, _ rhs: Self) -> Self
}
