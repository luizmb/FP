// MARK: - Traversal composition — named functions
//
// `Traversal` is the weakest optic, so *every* composition that involves a
// `Traversal` collapses to a `Traversal`. Each combo reduces to the single
// base case `Traversal ∘ Traversal` by widening the non-traversal side through
// its `.traversal` property (see Traversal.swift):
//
//   - `Traversal ∘ X`  →  `self.compose(X.traversal)`
//   - `X ∘ Traversal`  →  `self.traversal.compose(other)`
//
// ## CoW cost
//
// `modifyMut` is threaded through each link exactly as in the other optic
// compositions: `lhs.modifyMut(&s) { a in rhs.modifyMut(&a, f) }`. A chain is
// as cheap as its most expensive link; `[A].each` links are zero-copy.

// MARK: - Base case: Traversal ∘ Traversal

extension Traversal {
    /// Composes two traversals left-to-right: the foci of `self` are each fed into `other`,
    /// and the resulting foci are flattened. `getAll` flat-maps; `modifyMut` nests.
    public func compose<B>(_ other: Traversal<A, B>) -> Traversal<S, B> {
        Traversal<S, B>(
            getAll: { @Sendable s in getAll(s).flatMap(other.getAll) },
            modifyMut: { @Sendable s, f in modifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }

    /// Composes a traversal with an iso. Result is a `Traversal`.
    public func compose<B>(_ other: Iso<A, B>) -> Traversal<S, B> { compose(other.traversal) }
    /// Composes a traversal with a lens. Result is a `Traversal`.
    public func compose<B>(_ other: Lens<A, B>) -> Traversal<S, B> { compose(other.traversal) }
    /// Composes a traversal with a prism. Result is a `Traversal`.
    public func compose<B>(_ other: Prism<A, B>) -> Traversal<S, B> { compose(other.traversal) }
    /// Composes a traversal with an affine traversal. Result is a `Traversal`.
    public func compose<B>(_ other: AffineTraversal<A, B>) -> Traversal<S, B> { compose(other.traversal) }
}

// MARK: - {Iso, Lens, Prism, AffineTraversal} ∘ Traversal

extension Iso {
    /// Composes an iso with a traversal. Result is a `Traversal`.
    public func compose<B>(_ other: Traversal<A, B>) -> Traversal<S, B> { traversal.compose(other) }
}

extension Lens {
    /// Composes a lens with a traversal. Result is a `Traversal`.
    public func compose<B>(_ other: Traversal<A, B>) -> Traversal<S, B> { traversal.compose(other) }
}

extension Prism {
    /// Composes a prism with a traversal. Result is a `Traversal`.
    public func compose<B>(_ other: Traversal<A, B>) -> Traversal<S, B> { traversal.compose(other) }
}

extension AffineTraversal {
    /// Composes an affine traversal with a traversal. Result is a `Traversal`.
    public func compose<B>(_ other: Traversal<A, B>) -> Traversal<S, B> { traversal.compose(other) }
}
