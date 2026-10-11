// SPDX-License-Identifier: Apache-2.0

// MARK: - Optic composition — named functions

//
// These `compose` methods are the semantic layer for optic composition.
// The `>>>` and `<<<` operators in `CoreFPOperators` delegate to them;
// callers who import only `CoreFP` can use `compose` directly.
//
// ## CoW cost through a composition chain
//
// Each link in a chain contributes its own `modifyMut`/`tryModifyMut` copy
// cost. The composed optic chains them via nested closures:
//
//     lhs.modifyMut(&s) { a in rhs.modifyMut(&a, f) }
//
// This means the chain is as cheap as its most expensive individual link:
//
//   - Lens (WritableKeyPath) + Lens (WritableKeyPath) → zero-copy end to end
//   - Prism → zero-copy at that link (the old `S` is consumed first)
//   - ix on MutableCollection → zero-copy at that link
//   - ix on Dictionary → zero-copy at that link (through `values[index]`)
//
// The outer `S` is always `inout` and is never CoW-copied regardless of
// what appears inside the chain. A Prism link mutates its payload in place
// (it consumes the old `S` before the mutation runs; see Prism.swift).
//
// ## Composed `set`
//
// A composed `set` writes through the outer optic's in-place mutation and the
// inner optic's `set`: `outer.modifyMut(&whole) { a in a = inner.set(consume a, b) }`.
// Both ends take their value as `consuming`, so a `set` on a value the caller
// hands over runs in place end to end.
//
// ## Composition type table
//
// | LHS \ RHS        | Lens<A,B>          | Prism<A,B>              | AffineTraversal<A,B>    |
// |------------------|--------------------|-------------------------|-------------------------|
// | Lens<S,A>        | Lens<S,B>          | AffineTraversal<S,B>    | AffineTraversal<S,B>    |
// | Prism<S,A>       | AffineTraversal<S,B>| Prism<S,B>             | AffineTraversal<S,B>    |
// | AffineTraversal<S,A> | AffineTraversal<S,B>| AffineTraversal<S,B> | AffineTraversal<S,B> |
//
// See also IsoComposition.swift in CoreFPOperators for Iso >>> Iso/Lens/Prism/AT combinations.

// MARK: - Lens compositions

public extension Lens {
    /// Composes two lenses left-to-right, focusing from `S` through `A` to `B`.
    /// Both `modifyMut` closures are chained; zero-copy when both lenses are
    /// `WritableKeyPath`-backed.
    func compose<B>(_ other: Lens<A, B>) -> Lens<S, B> {
        Lens<S, B>(
            get: { @Sendable s in other.get(get(s)) },
            set: setThrough(modifyMut, other.set),
            modifyMut: { @Sendable s, f in modifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }

    /// Composes a lens with a prism, yielding an `AffineTraversal<S, B>`.
    /// The lens part is zero-copy (if `WritableKeyPath`-backed); the prism mutates
    /// its payload in place.
    func compose<B>(_ other: Prism<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { @Sendable s in other.preview(get(s)) },
            set: setThrough(modifyMut) { (a: consuming A, b: B) in other.set(consume a, b) },
            tryModifyMut: { @Sendable s, f in modifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }

    /// Composes a lens with an affine traversal, yielding an `AffineTraversal<S, B>`.
    /// The lens part is zero-copy (if `WritableKeyPath`-backed); the traversal
    /// contributes its own copy cost (e.g. zero for `ix` on `MutableCollection`).
    func compose<B>(_ other: AffineTraversal<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { @Sendable s in other.preview(get(s)) },
            set: setThrough(modifyMut, other.set),
            tryModifyMut: { @Sendable s, f in modifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }
}

// MARK: - Prism compositions

public extension Prism {
    /// Composes two prisms left-to-right. Each link mutates its payload in place.
    func compose<B>(_ other: Prism<A, B>) -> Prism<S, B> {
        Prism<S, B>(
            preview: { @Sendable s in preview(s).flatMap(other.preview) },
            review: { @Sendable b in review(other.review(b)) },
            tryModifyMut: { @Sendable s, f in tryModifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }

    /// Composes a prism with a lens, yielding an `AffineTraversal<S, B>`.
    func compose<B>(_ other: Lens<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { @Sendable s in preview(s).map(other.get) },
            set: setThrough(tryModifyMut, other.set),
            tryModifyMut: { @Sendable s, f in tryModifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }

    /// Composes a prism with an affine traversal, yielding an `AffineTraversal<S, B>`.
    func compose<B>(_ other: AffineTraversal<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { @Sendable s in preview(s).flatMap(other.preview) },
            set: setThrough(tryModifyMut, other.set),
            tryModifyMut: { @Sendable s, f in tryModifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }
}

// MARK: - AffineTraversal compositions

public extension AffineTraversal {
    /// Composes an affine traversal with a lens, yielding an `AffineTraversal<S, B>`.
    func compose<B>(_ other: Lens<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { @Sendable s in preview(s).map(other.get) },
            set: setThrough(tryModifyMut, other.set),
            tryModifyMut: { @Sendable s, f in tryModifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }

    /// Composes two affine traversals left-to-right.
    func compose<B>(_ other: Prism<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { @Sendable s in preview(s).flatMap(other.preview) },
            set: setThrough(tryModifyMut) { (a: consuming A, b: B) in other.set(consume a, b) },
            tryModifyMut: { @Sendable s, f in tryModifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }

    /// Composes two affine traversals left-to-right.
    func compose<B>(_ other: AffineTraversal<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { @Sendable s in preview(s).flatMap(other.preview) },
            set: setThrough(tryModifyMut, other.set),
            tryModifyMut: { @Sendable s, f in tryModifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }
}

// MARK: - Composed set

/// The `set` of a composed optic: writes `b` through the outer optic's in-place mutation
/// and the inner optic's `set`. The whole and each focus are moved along, never shared, so
/// the write is in place whenever the caller hands the whole over.
private func setThrough<S, A, B>(
    _ outer: @escaping @Sendable (inout S, (inout A) -> Void) -> Void,
    _ inner: @escaping @Sendable (consuming A, B) -> A
) -> @Sendable (consuming S, B) -> S {
    { (s: consuming S, b: B) in
        var whole = consume s
        outer(&whole) { a in a = inner(consume a, b) }
        return whole
    }
}
