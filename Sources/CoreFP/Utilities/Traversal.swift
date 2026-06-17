// MARK: - Traversal<S, A>
//
// A `Traversal` focuses on zero, one, or many values of type `A` inside `S`.
// It is the most general optic in the hierarchy: every other optic (`Iso`,
// `Lens`, `Prism`, `AffineTraversal`) can be widened to a `Traversal`, and any
// composition that involves a `Traversal` collapses to a `Traversal`.
//
// ## Core primitives
//
//   - `getAll: (S) -> [A]` — extract every focused value, in order.
//   - `modifyMut: (inout S, (inout A) -> Void) -> Void` — apply a mutation to
//     every focus in place. The copy cost depends on how the traversal was
//     built; `[A].each` mutates `inout collection[i]` directly (zero-copy on
//     the buffer), while compositions thread `modifyMut` through each layer.
//
// `getAll` and `modifyMut` are independent closures so a traversal can be
// constructed with the most efficient write path available (mirroring
// `AffineTraversal`'s `preview`/`set`/`tryModifyMut` split).
//
// ## lift and compose
//
// `lift` turns an `EndoMut<A>` into an `EndoMut<S>` that runs the mutation on
// every focus. `compose` (and `>>>`) combine a traversal with any other optic;
// the result is always a `Traversal`.

/// An optic that focuses on zero, one, or many values of type `A` inside a whole `S`.
///
/// `Traversal<S, A>` generalises ``AffineTraversal`` (which focuses on 0..1) to **0..n** foci.
/// It is the weakest, most general optic: composing any optic with a `Traversal` yields a
/// `Traversal`.
///
/// ## Core primitives
///
/// | Property | Type | Purpose |
/// |----------|------|---------|
/// | `getAll` | `(S) -> [A]` | Extract every focused value, in order |
/// | `modifyMut` | `(inout S, (inout A) -> Void) -> Void` | Apply a mutation to every focus in place |
///
/// ## Creating traversals
///
/// The canonical source is ``Swift/Array/each`` (and the other `each` collection traversals),
/// or composing an existing optic with one:
///
/// ```swift
/// let allScores: Traversal<[Int], Int> = [Int].each
/// allScores.getAll([10, 20, 30])               // [10, 20, 30]
/// allScores.over { $0 + 1 }([10, 20, 30])      // [11, 21, 31]
///
/// // Via composition (requires CoreFPOperators for >>>):
/// let allCityNames: Traversal<Company, String> =
///     ^\Company.employees >>> [Employee].each >>> ^\Employee.city
/// ```
///
/// ## CoW cost
///
/// As with ``AffineTraversal``, the write cost depends on the backing optic:
/// - `[A].each` on a `MutableCollection` → zero-copy (direct `inout` element access)
/// - `[K: V].eachValue` → copies each `Value` once
/// - Composition → threads `modifyMut` through each layer
///
/// - Note: For the identity traversal (where `S == A`, a single focus), use ``Traversal/id``.
/// - SeeAlso: ``Lens``, ``Prism``, ``AffineTraversal``, ``Iso``, ``IndexedTraversal``, ``EndoMut``
public struct Traversal<S, A>: Sendable {
    /// Extracts every focused value from `S`, in traversal order.
    public let getAll: @Sendable (S) -> [A]

    /// Applies `f` to every focused value in place. `S` is kept `inout` throughout; copy cost
    /// depends on the specific traversal — see the file-level comment.
    public let modifyMut: @Sendable (inout S, (inout A) -> Void) -> Void

    /// Full init. Supply both the read path (`getAll`) and the in-place write path (`modifyMut`).
    public init(
        getAll: @escaping @Sendable (S) -> [A],
        modifyMut: @escaping @Sendable (inout S, (inout A) -> Void) -> Void
    ) {
        self.getAll = getAll
        self.modifyMut = modifyMut
    }

    /// Returns every focused value. Same as ``getAll``, enabling call syntax: `traversal(whole)`.
    public func callAsFunction(_ whole: S) -> [A] { getAll(whole) }

    /// Applies a pure transform to every focus; returns a new `S`.
    /// Prefer ``lift(_:)`` when working with `EndoMut` and large CoW states.
    public func over(_ transform: @escaping @Sendable (A) -> A) -> @Sendable (S) -> S {
        { s in var c = s; modifyMut(&c) { a in a = transform(a) }; return c }
    }

    /// Replaces every focus with `value`; returns a new `S`. (Foci that are absent stay absent.)
    public func setAll(_ whole: S, _ value: A) -> S {
        var c = whole
        modifyMut(&c) { a in a = value }
        return c
    }

    /// Lifts an `EndoMut<A>` into an `EndoMut<S>` that runs the mutation on every focus.
    /// When there are no foci the resulting `EndoMut` is a no-op.
    public func lift(_ f: EndoMut<A>) -> EndoMut<S> {
        EndoMut { s in modifyMut(&s) { a in f(&a) } }
    }
}

extension Traversal where S == A {
    /// The identity traversal: a single focus that is the whole value itself.
    public static var id: Traversal<S, S> {
        Traversal(getAll: { [$0] }, modifyMut: { s, f in f(&s) })
    }
}

// MARK: - Widening other optics to Traversal

extension Lens {
    /// Widens this lens to a single-focus ``Traversal``.
    public var traversal: Traversal<S, A> {
        Traversal(getAll: { [get($0)] }, modifyMut: { s, f in var a = get(s); f(&a); s = set(s, a) })
    }
}

extension Prism {
    /// Widens this prism to a 0..1-focus ``Traversal``.
    public var traversal: Traversal<S, A> {
        Traversal(
            getAll: { preview($0).map { [$0] } ?? [] },
            modifyMut: { s, f in guard var a = preview(s) else { return }; f(&a); s = review(a) }
        )
    }
}

extension Iso {
    /// Widens this iso to a single-focus ``Traversal``.
    public var traversal: Traversal<S, A> {
        Traversal(getAll: { [get($0)] }, modifyMut: { s, f in var a = get(s); f(&a); s = reverseGet(a) })
    }
}

extension AffineTraversal {
    /// Widens this affine traversal to a 0..1-focus ``Traversal``.
    public var traversal: Traversal<S, A> {
        Traversal(
            getAll: { preview($0).map { [$0] } ?? [] },
            modifyMut: { s, f in tryModifyMut(&s, f) }
        )
    }
}
