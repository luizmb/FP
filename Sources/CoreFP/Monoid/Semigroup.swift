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
public protocol Semigroup: Sendable {
    /// Combines two values using the associative operation.
    ///
    /// The operation must satisfy associativity:
    /// `combine(combine(a, b), c) == combine(a, combine(b, c))`
    static func combine(_ lhs: Self, _ rhs: Self) -> Self

    /// Folds a non-empty run of values left-to-right.
    ///
    /// A **customization point**: the default folds pairwise with ``combine(_:_:)``, which is
    /// O(n) calls — but for a type whose `combine` copies a growing accumulator (any
    /// concatenative `Semigroup`, e.g. `Array`/`String`), that default is O(n²). Such types
    /// should override `sconcat` with a single-pass build.
    ///
    /// Because this is a protocol *requirement* (not an extension-only method), overrides are
    /// dispatched dynamically — so a generic caller, the free ``sconcat(_:_:)`` function, and
    /// the default ``Monoid/mconcat(_:)`` all pick up a type's override.
    static func sconcat(_ first: Self, _ rest: [Self]) -> Self
}

public extension Semigroup {
    /// Default `sconcat`: left fold via ``combine(_:_:)``. O(n) calls to `combine`.
    static func sconcat(_ first: Self, _ rest: [Self]) -> Self {
        rest.reduce(first, combine)
    }
}
