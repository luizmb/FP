// SPDX-License-Identifier: Apache-2.0
/// A bidirectional, lossless conversion between `S` and `A`.
///
/// An `Iso<S, A>` captures a total bijection: `get` converts `S → A` and
/// `reverseGet` converts `A → S`, and the two are mutual inverses:
///
/// ```swift
/// iso.reverseGet(iso.get(s)) == s   // round-trip from S
/// iso.get(iso.reverseGet(a)) == a   // round-trip from A
/// ```
///
/// Every `Iso` is also a valid ``Lens``, ``Prism``, and ``AffineTraversal``, and can be
/// composed freely with all of them via `>>>` / `<<<` (from `CoreFPOperators`).
///
/// ## Creating isos
///
/// Use the free-function ``iso(get:reverseGet:)`` with explicit forward and reverse functions:
///
/// ```swift
/// let celsiusToFahrenheit = iso(
///     get: { celsius in celsius * 9 / 5 + 32 },
///     reverseGet: { fahrenheit in (fahrenheit - 32) * 5 / 9 }
/// )
///
/// celsiusToFahrenheit.get(0.0)             // 32.0
/// celsiusToFahrenheit.reverseGet(32.0)     // 0.0
/// celsiusToFahrenheit.reverse.get(32.0)    // 0.0
/// ```
///
/// ## Using isos
///
/// An `Iso<S, A>` can be used anywhere a ``Lens``, ``Prism``, or ``AffineTraversal`` is
/// expected by converting via ``asLens``, ``asPrism``, or ``asAffineTraversal``:
///
/// ```swift
/// let myLens: Lens<S, A> = myIso.asLens
/// ```
///
/// `Iso` also supports in-place mutation via ``lift(_:)`` and a pure ``over(_:)`` transform.
///
/// ## Monoid structure
///
/// When `S == A` (an endomorphism iso), `Iso<A, A>` forms a ``Monoid`` under sequential
/// composition. This lets you combine a sequence of lossless transforms with ``mconcat``:
///
/// ```swift
/// let transform: Iso<Point, Point> = mconcat([rotate, scale, translate])
/// transform.get(point)          // all three applied in order
/// transform.reverse.get(point)  // all three reversed, in reverse order
/// ```
///
/// ## Composition
///
/// Isos compose with other isos to yield isos, and with any weaker optic to yield that
/// weaker optic. Use the `>>>` operator from `CoreFPOperators`:
///
/// ```swift
/// let composed: Iso<A, C> = isoAB >>> isoBC
/// let weakened: Lens<A, C> = isoAB >>> lensBC
/// ```
///
/// - Note: For the identity iso (where `S == A`), use ``Iso/id``.
/// - SeeAlso: ``Lens``, ``Prism``, ``AffineTraversal``, ``EndoMut``
public struct Iso<S, A>: Sendable {
    public let get: @Sendable (S) -> A
    public let reverseGet: @Sendable (A) -> S

    public init(get: @escaping @Sendable (S) -> A, reverseGet: @escaping @Sendable (A) -> S) {
        self.get = get
        self.reverseGet = reverseGet
    }

    public func callAsFunction(_ whole: S) -> A { get(whole) }

    /// The inverse iso — swaps `get` and `reverseGet`.
    public var reverse: Iso<A, S> {
        Iso<A, S>(get: reverseGet, reverseGet: get)
    }

    /// Apply a transform through the iso: convert to `A`, transform, convert back.
    public func over(_ transform: @escaping @Sendable (A) -> A) -> @Sendable (consuming S) -> S {
        { (s: consuming S) in reverseGet(transform(get(s))) }
    }

    /// Converts `S → A`, runs `f` on `inout A`, then rebuilds `S` with `reverseGet`.
    ///
    /// `reverseGet` needs nothing from the old `S`, so the old `S` is consumed before `f`
    /// runs: `f` is the only owner of `A` and mutates a CoW payload in place.
    public func modifyMut(_ s: inout S, _ f: (inout A) -> Void) {
        let whole = consume s
        var part = get(whole)
        _ = consume whole // end `whole` here so `part` is the payload's only owner
        f(&part)
        s = reverseGet(part)
    }

    /// Lifts an `EndoMut<A>` into an `EndoMut<S>` through this iso, mutating in place
    /// (see ``modifyMut(_:_:)``).
    public func lift(_ f: EndoMut<A>) -> EndoMut<S> {
        EndoMut { s in modifyMut(&s) { a in f(&a) } }
    }

    /// View this iso as a `Lens` whose `modifyMut` mutates in place (see ``modifyMut(_:_:)``).
    public var asLens: Lens<S, A> {
        Lens(
            get: get,
            set: { _, a in reverseGet(a) },
            modifyMut: { s, f in modifyMut(&s, f) }
        )
    }

    /// View this iso as a `Prism`. Preview always succeeds; review uses `reverseGet`.
    /// `tryModifyMut` mutates in place (see ``modifyMut(_:_:)``).
    public var asPrism: Prism<S, A> {
        Prism(
            preview: { .some(get($0)) },
            review: reverseGet,
            tryModifyMut: { s, f in modifyMut(&s, f) }
        )
    }

    /// View this iso as an `AffineTraversal`. The focus is always present;
    /// `tryModifyMut` mutates in place (see ``modifyMut(_:_:)``).
    public var asAffineTraversal: AffineTraversal<S, A> {
        AffineTraversal(
            preview: { .some(get($0)) },
            set: { _, a in reverseGet(a) },
            tryModifyMut: { s, f in modifyMut(&s, f) }
        )
    }
}

public extension Iso where S == A {
    /// The identity `Iso`: both directions are the identity function.
    /// This is the strongest identity optic; use `.asLens`, `.asPrism`, or `.asAffineTraversal`
    /// to obtain weaker forms.
    static var id: Iso<S, S> {
        Iso(get: { $0 }, reverseGet: { $0 })
    }
}

/// Builds an `Iso` from explicit forward and reverse functions.
///
/// ```swift
/// let addOne = iso(get: { $0 + 1 }, reverseGet: { $0 - 1 })
/// addOne.get(5)            // 6
/// addOne.reverseGet(6)     // 5
/// addOne.reverse.get(6)    // 5
/// ```
public func iso<S, A>(get: @escaping @Sendable (S) -> A, reverseGet: @escaping @Sendable (A) -> S) -> Iso<S, A> {
    Iso(get: get, reverseGet: reverseGet)
}
