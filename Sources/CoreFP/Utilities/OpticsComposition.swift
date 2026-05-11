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
//   - Any Prism in the chain → copies the enum case value at that link
//   - ix on MutableCollection → zero-copy at that link
//   - ix on Dictionary → copies Value at that link
//
// The outer `S` is always `inout` and is never CoW-copied regardless of
// what appears inside the chain.

// MARK: - Lens compositions

extension Lens {
    /// Composes two lenses left-to-right, focusing from `S` through `A` to `B`.
    /// Both `modifyMut` closures are chained; zero-copy when both lenses are
    /// `WritableKeyPath`-backed.
    public func compose<B>(_ other: Lens<A, B>) -> Lens<S, B> {
        Lens<S, B>(
            get: { other.get(get($0)) },
            set: { s, b in set(s, other.set(get(s), b)) },
            modifyMut: { s, f in modifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }

    /// Composes a lens with a prism, yielding an `AffineTraversal<S, B>`.
    /// The lens part is zero-copy (if `WritableKeyPath`-backed); the prism
    /// copies the enum case value at its link.
    public func compose<B>(_ other: Prism<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { other.preview(get($0)) },
            set: { s, b in set(s, other.review(b)) },
            tryModifyMut: { s, f in modifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }

    /// Composes a lens with an affine traversal, yielding an `AffineTraversal<S, B>`.
    /// The lens part is zero-copy (if `WritableKeyPath`-backed); the traversal
    /// contributes its own copy cost (e.g. zero for `ix` on `MutableCollection`).
    public func compose<B>(_ other: AffineTraversal<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { other.preview(get($0)) },
            set: { s, b in set(s, other.set(get(s), b)) },
            tryModifyMut: { s, f in modifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }
}

// MARK: - Prism compositions

extension Prism {
    /// Composes two prisms left-to-right. Each link copies its enum case value;
    /// the outer `S` is `inout` and is never CoW-copied.
    public func compose<B>(_ other: Prism<A, B>) -> Prism<S, B> {
        Prism<S, B>(
            preview: { preview($0).flatMap(other.preview) },
            review: { review(other.review($0)) },
            tryModifyMut: { s, f in tryModifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }

    /// Composes a prism with a lens, yielding an `AffineTraversal<S, B>`.
    public func compose<B>(_ other: Lens<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { preview($0).map(other.get) },
            set: { s, b in preview(s).map { a in review(other.set(a, b)) } ?? s },
            tryModifyMut: { s, f in tryModifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }

    /// Composes a prism with an affine traversal, yielding an `AffineTraversal<S, B>`.
    public func compose<B>(_ other: AffineTraversal<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { preview($0).flatMap(other.preview) },
            set: { s, b in preview(s).map { a in review(other.set(a, b)) } ?? s },
            tryModifyMut: { s, f in tryModifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }
}

// MARK: - AffineTraversal compositions

extension AffineTraversal {
    /// Composes an affine traversal with a lens, yielding an `AffineTraversal<S, B>`.
    public func compose<B>(_ other: Lens<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { preview($0).map(other.get) },
            set: { s, b in preview(s).map { a in set(s, other.set(a, b)) } ?? s },
            tryModifyMut: { s, f in tryModifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }

    /// Composes two affine traversals left-to-right.
    public func compose<B>(_ other: Prism<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { preview($0).flatMap(other.preview) },
            set: { s, b in preview(s).map { _ in set(s, other.review(b)) } ?? s },
            tryModifyMut: { s, f in tryModifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }

    /// Composes two affine traversals left-to-right.
    public func compose<B>(_ other: AffineTraversal<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { preview($0).flatMap(other.preview) },
            set: { s, b in preview(s).map { a in set(s, other.set(a, b)) } ?? s },
            tryModifyMut: { s, f in tryModifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }
}
