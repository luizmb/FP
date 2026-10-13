// SPDX-License-Identifier: Apache-2.0

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
/// - `[K: V].eachValue` → zero-copy (in place through `values[index]`)
/// - Composition → threads `modifyMut` through each layer
///
/// - Note: For the identity traversal (where `S == A`, a single focus), use ``Traversal/id``.
/// - SeeAlso: ``Lens``, ``Prism``, ``AffineTraversal``, ``Iso``, ``IndexedTraversal``, ``EndoMut``
public struct Traversal<S, A>: Sendable {
    /// Extracts every focused value from `S`, in traversal order.
    public let getAll: @Sendable (S) -> [A]

    /// Feeds every focused value to `body`, in traversal order, without collecting them.
    ///
    /// This is the fold primitive (Haskell's `foldMapOf`, written in continuation-passing style
    /// because a stored Swift closure can't be generic over the accumulator). Composition nests
    /// it, so a chain of any depth visits the leaves in one pass and builds no intermediate
    /// arrays. ``reduce(_:into:_:)``, ``foldMap(_:_:)`` and ``count(_:)`` are built on it, and a
    /// composed traversal's ``getAll`` collects through it into a single array.
    public let forEach: @Sendable (S, (A) -> Void) -> Void

    /// Applies `f` to every focused value in place. `S` is kept `inout` throughout; copy cost
    /// depends on the specific traversal — see the file-level comment.
    public let modifyMut: @Sendable (inout S, (inout A) -> Void) -> Void

    /// Full init. Supply the bulk read (`getAll`), the fold (`forEach`) and the in-place write
    /// (`modifyMut`). Use it when `getAll` has a faster path than collecting `forEach` (e.g.
    /// `Array($0)` shares the buffer).
    public init(
        getAll: @escaping @Sendable (S) -> [A],
        forEach: @escaping @Sendable (S, (A) -> Void) -> Void,
        modifyMut: @escaping @Sendable (inout S, (inout A) -> Void) -> Void
    ) {
        self.getAll = getAll
        self.forEach = forEach
        self.modifyMut = modifyMut
    }

    /// Fold-first init: `getAll` collects `forEach` into one array.
    public init(
        forEach: @escaping @Sendable (S, (A) -> Void) -> Void,
        modifyMut: @escaping @Sendable (inout S, (inout A) -> Void) -> Void
    ) {
        self.init(
            getAll: { s in
                var all: [A] = []
                forEach(s) { all.append($0) }
                return all
            },
            forEach: forEach,
            modifyMut: modifyMut
        )
    }

    /// Array-first init: `forEach` walks the array `getAll` returns. Prefer
    /// ``init(forEach:modifyMut:)`` when the foci can be visited without building that array.
    public init(
        getAll: @escaping @Sendable (S) -> [A],
        modifyMut: @escaping @Sendable (inout S, (inout A) -> Void) -> Void
    ) {
        self.init(
            getAll: getAll,
            forEach: { s, body in
                for a in getAll(s) {
                    body(a)
                }
            },
            modifyMut: modifyMut
        )
    }

    /// Returns every focus. Same as ``getAll``, enabling call syntax: `traversal(whole)`.
    public func callAsFunction(_ whole: S) -> [A] { getAll(whole) }

    /// Folds every focus into `initial`, mutating the accumulator in place. Builds no array.
    public func reduce<R>(_ whole: S, into initial: R, _ combine: (inout R, A) -> Void) -> R {
        var result = initial
        forEach(whole) { combine(&result, $0) }
        return result
    }

    /// Maps every focus into a ``Monoid`` and combines them in order (Haskell's `foldMapOf`).
    /// Builds no array; returns ``Monoid/identity`` when there are no foci.
    public func foldMap<M: Monoid>(_ whole: S, _ transform: (A) -> M) -> M {
        reduce(whole, into: M.identity) { acc, a in acc = M.combine(acc, transform(a)) }
    }

    /// The number of foci (Haskell's `lengthOf`). Builds no array.
    public func count(_ whole: S) -> Int {
        reduce(whole, into: 0) { n, _ in n += 1 }
    }

    /// Applies a pure transform to every focus; returns a new `S`.
    /// Prefer ``lift(_:)`` when working with `EndoMut` and large CoW states.
    public func over(_ transform: @escaping @Sendable (A) -> A) -> @Sendable (consuming S) -> S {
        { (s: consuming S) in
            var whole = consume s
            modifyMut(&whole) { a in a = transform(a) }
            return whole
        }
    }

    /// Replaces every focus with `value`; returns a new `S`. (Foci that are absent stay absent.)
    /// In place when the caller hands `whole` over (`consume x`, or a temporary).
    public func setAll(_ whole: consuming S, _ value: A) -> S {
        var result = consume whole
        modifyMut(&result) { a in a = value }
        return result
    }

    /// Lifts an `EndoMut<A>` into an `EndoMut<S>` that runs the mutation on every focus.
    /// When there are no foci the resulting `EndoMut` is a no-op.
    public func lift(_ f: EndoMut<A>) -> EndoMut<S> {
        EndoMut { s in modifyMut(&s) { a in f(&a) } }
    }
}

public extension Traversal where S == A {
    /// The identity traversal: a single focus that is the whole value itself.
    static var id: Traversal<S, S> {
        Traversal(getAll: { [$0] }, forEach: { s, body in body(s) }, modifyMut: { s, f in f(&s) })
    }
}

// MARK: - Widening other optics to Traversal

public extension Lens {
    /// Widens this lens to a single-focus ``Traversal``. Mutation goes through the lens's own
    /// `modifyMut`, so a key-path lens stays zero-copy (`^\S.items >>> [Item].each` mutates
    /// the array in place).
    var traversal: Traversal<S, A> {
        Traversal(getAll: { [get($0)] }, forEach: { s, body in body(get(s)) }, modifyMut: modifyMut)
    }
}

public extension Prism {
    /// Widens this prism to a 0..1-focus ``Traversal``.
    var traversal: Traversal<S, A> {
        Traversal(
            getAll: { preview($0).map { [$0] } ?? [] },
            forEach: { s, body in if let a = preview(s) { body(a) } },
            modifyMut: tryModifyMut
        )
    }
}

public extension Iso {
    /// Widens this iso to a single-focus ``Traversal``.
    var traversal: Traversal<S, A> {
        Traversal(getAll: { [get($0)] }, forEach: { s, body in body(get(s)) }, modifyMut: { s, f in modifyMut(&s, f) })
    }
}

public extension AffineTraversal {
    /// Widens this affine traversal to a 0..1-focus ``Traversal``.
    var traversal: Traversal<S, A> {
        Traversal(
            getAll: { preview($0).map { [$0] } ?? [] },
            forEach: { s, body in if let a = preview(s) { body(a) } },
            modifyMut: { s, f in tryModifyMut(&s, f) }
        )
    }
}
