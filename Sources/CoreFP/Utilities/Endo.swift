// MARK: - Endo<A>

// Endo wraps an endomorphism — a function from a type to itself, `(A) -> A`.
//
// Its defining feature is the Monoid under composition: a sequence of
// transformations collapses into one with `mconcat`, and the identity element
// is the do-nothing function. Use Endo when the transformations are one-way
// (no inverse needed); use `Iso<A, A>` when you also need to undo them.
//
// ```swift
// let trim    = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
// let lower   = Endo<String> { $0.lowercased() }
// let exclaim = Endo<String> { $0 + "!" }
//
// let normalize: Endo<String> = mconcat([trim, lower, exclaim])
// normalize.run("  HELLO  ")  // "hello!"
// ```

/// A wrapper around a pure endomorphism `(A) -> A` that forms a ``Monoid`` under composition.
///
/// `Endo<A>` is the canonical way to represent a sequence of same-type transformations that
/// can be combined and applied as one. It wraps any `(A) -> A` function and uses sequential
/// application (left-to-right) as its ``Semigroup/combine(_:_:)`` operation, with the
/// identity function as ``Monoid/identity``.
///
/// ## When to use Endo vs EndoMut
///
/// - Use `Endo<A>` for small, value-semantic types or when you need a pure `(A) -> A` API.
/// - Use ``EndoMut`` for large types with Copy-on-Write internals (`Array`, `Dictionary`,
///   `String`) to avoid O(n) buffer copies. The two are interconvertible via
///   ``Endo/toEndoMut()`` and ``EndoMut/toEndo()``.
///
/// ## Example
///
/// ```swift
/// let trim    = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
/// let lower   = Endo<String> { $0.lowercased() }
/// let exclaim = Endo<String> { $0 + "!" }
///
/// // Combine into a single transform using the Monoid:
/// let normalize: Endo<String> = mconcat([trim, lower, exclaim])
/// normalize("  HELLO  ")   // "hello!"
///
/// // Or use <> (requires CoreFPOperators):
/// let normalize2 = trim <> lower <> exclaim
/// ```
///
/// ## Monoid laws
///
/// - `mconcat([])` returns the identity (`Endo { $0 }`).
/// - `mconcat([f, g])` is equivalent to `f` then `g`.
///
/// - SeeAlso: ``EndoMut``, ``Iso``, ``mconcat(_:)``, ``sconcat(_:_:)``
public struct Endo<A>: Sendable {
    public let runEndo: @Sendable (A) -> A

    public init(_ fn: @escaping @Sendable (A) -> A) {
        runEndo = fn
    }

    public func callAsFunction(_ value: A) -> A {
        runEndo(value)
    }
}

/// Free-function constructor — mirrors `Reader { … }` / `iso(get:reverseGet:)` style.
public func endo<A>(_ fn: @escaping @Sendable (A) -> A) -> Endo<A> {
    Endo(fn)
}
