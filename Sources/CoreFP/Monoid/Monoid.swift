/// A ``Semigroup`` with an identity element.
///
/// A `Monoid` extends ``Semigroup`` by providing an identity element, ``identity``,
/// that satisfies the left and right identity laws:
///
/// ```
/// combine(identity, x) == x   // left identity
/// combine(x, identity) == x   // right identity
/// ```
///
/// Together with associativity (inherited from ``Semigroup``), these laws make `Monoid`
/// the algebraic foundation for folding sequences: ``mconcat(_:)`` reduces any `[M]`
/// to a single `M`, returning `identity` for the empty array.
///
/// ## Standard conformances
///
/// All types that conform to ``Semigroup`` in this library also conform to `Monoid`,
/// except ``NonEmpty`` (which deliberately has no identity — the empty sequence is
/// not a valid `NonEmpty`). Notable identities:
///
/// | Type | Identity |
/// |------|---------|
/// | `[A]` | `[]` |
/// | `Set<A>` | `Set()` |
/// | `String` | `""` |
/// | ``Endo``<A> | `Endo { $0 }` |
/// | ``EndoMut``<A> | `EndoMut { _ in }` |
/// | `NumericMonoid<T>.Sum` | `0` |
/// | `NumericMonoid<T>.Product` | `1` |
/// | `Bool.Monoids.And` | `true` |
/// | `Bool.Monoids.Or` | `false` |
///
/// ## Folding with mconcat
///
/// ```swift
/// mconcat([1, 2, 3] as [NumericMonoid<Int>.Sum])   // Sum(6)
/// mconcat([] as [Endo<String>])                     // Endo { $0 }  (identity)
/// mconcat([trimEndo, lowerEndo, exclaimEndo])       // composed transform
/// ```
///
/// - SeeAlso: ``Semigroup``, ``mconcat(_:)``, ``sconcat(_:_:)``
public protocol Monoid: Semigroup {
    /// The identity element for ``Semigroup/combine(_:_:)``.
    ///
    /// Must satisfy:
    /// - `combine(identity, x) == x` (left identity)
    /// - `combine(x, identity) == x` (right identity)
    static var identity: Self { get }
}
