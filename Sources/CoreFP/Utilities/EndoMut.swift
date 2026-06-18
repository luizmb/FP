// SPDX-License-Identifier: Apache-2.0

// MARK: - EndoMut<A>

// EndoMut wraps an in-place endomorphism — `(inout A) -> Void`.
//
// It is the cost-free companion to `Endo<A>` for Swift value types with
// Copy-on-Write (CoW) internals (Array, Dictionary, Set, String). When
// `Endo<A>` receives a value, the caller still holds a strong reference to
// every CoW buffer for the duration of the call, raising the reference count
// to at least 2. Any mutation inside the function therefore triggers an O(n)
// heap copy of the entire buffer — even if only one element changes.
//
// `EndoMut` passes the value by exclusive reference instead. Swift's Law of
// Exclusivity (SE-0176) statically guarantees that no other code holds an
// alias to the value during the call, so CoW sees a reference count of 1 and
// mutates the buffer in place — zero copying regardless of the buffer's size.
//
// The algebra is identical to `Endo<A>`: both form a `Monoid` under sequential
// application with the do-nothing closure as the identity element. `EndoMut`
// and `Endo` are isomorphic as monoids; use the `.toEndo()` / `.toEndoMut()`
// bridges to convert between them.
//
// ```swift
// var items = Array(0..<10_000)
//
// let clamp = EndoMut<[Int]> { xs in for i in xs.indices { xs[i] = min(xs[i], 100) } }
// let sort  = EndoMut<[Int]> { $0.sort() }
//
// let normalise: EndoMut<[Int]> = mconcat([clamp, sort])
// normalise.runEndoMut(&items)   // clamps first, then sorts — no copies
// normalise(&items)              // callAsFunction also works
// ```

/// A wrapper around an in-place endomorphism `(inout A) -> Void` that forms a ``Monoid``
/// under sequential application.
///
/// `EndoMut<A>` is the zero-copy companion to ``Endo``. For Swift value types with
/// Copy-on-Write (CoW) internals (`Array`, `Dictionary`, `Set`, `String`), passing a
/// value *by value* to a function raises the buffer refcount to at least 2, triggering
/// an O(n) heap copy on the first mutation inside the function. `EndoMut` avoids this
/// by taking the value as `inout` — Swift's Law of Exclusivity guarantees no alias exists
/// during the call, so CoW mutates in place.
///
/// ## Monoid instance
///
/// Like ``Endo``, `EndoMut` is a ``Monoid``:
/// - ``EndoMut/identity``: the do-nothing closure (`{ _ in }`).
/// - ``Semigroup/combine(_:_:)``: sequential application — `lhs` runs first, then `rhs`.
///
/// ## Example: combining reducers for a large CoW state
///
/// ```swift
/// var items = Array(0..<10_000)
///
/// let clamp = EndoMut<[Int]> { xs in
///     for i in xs.indices { xs[i] = min(xs[i], 100) }
/// }
/// let sort = EndoMut<[Int]> { $0.sort() }
///
/// // Combine without copying:
/// let normalize: EndoMut<[Int]> = mconcat([clamp, sort])
/// normalize(&items)   // clamps then sorts — zero CoW copies
/// ```
///
/// ## Interoperability with Endo
///
/// ```swift
/// let mutating = EndoMut<String> { $0 = $0.uppercased() }
/// let pure = mutating.toEndo()         // Endo<String> — copies once
///
/// let pure2 = Endo<String> { $0.uppercased() }
/// let mutating2 = pure2.toEndoMut()   // free, no allocation
/// ```
///
/// ## Integration with optics
///
/// ``Lens/lift(_:)``, ``Prism/lift(_:)``, and ``AffineTraversal/lift(_:)`` all accept
/// `EndoMut` and produce an `EndoMut` for the outer type, preserving the zero-copy
/// guarantee when the lens is `WritableKeyPath`-backed.
///
/// - SeeAlso: ``Endo``, ``Lens/lift(_:)``, ``mconcat(_:)``
public struct EndoMut<A>: Sendable {
    public let runEndoMut: @Sendable (inout A) -> Void

    public init(_ fn: @escaping @Sendable (inout A) -> Void) {
        runEndoMut = fn
    }

    public func callAsFunction(_ value: inout A) {
        runEndoMut(&value)
    }
}

/// Free-function constructor — mirrors `endo { … }` style.
public func endoMut<A>(_ fn: @escaping @Sendable (inout A) -> Void) -> EndoMut<A> {
    EndoMut(fn)
}
