// SPDX-License-Identifier: Apache-2.0

// MARK: - Traversal composition — named functions

//
// `Traversal` is the weakest optic, so *every* composition that involves a
// `Traversal` collapses to a `Traversal`. `forEach` and `modifyMut` nest the
// same way in every combo (`lhs.forEach(s) { a in rhs.forEach(a, body) }`), so
// a chain of any depth visits its leaves in one pass. Only `getAll` differs:
//
//   - `Traversal ∘ Traversal`: one result array, each inner `getAll` appended
//     in bulk.
//   - `Traversal ∘ X` (X has at most one focus): one result array, filled by
//     `forEach`, with no one-element array per focus.
//   - `X ∘ Traversal`: the inner traversal's own `getAll` of X's focus.
//
// ## CoW cost
//
// `modifyMut` is threaded through each link exactly as in the other optic
// compositions: `lhs.modifyMut(&s) { a in rhs.modifyMut(&a, f) }`. A chain is
// as cheap as its most expensive link; `[A].each` links are zero-copy.

// MARK: - Base case: Traversal ∘ Traversal

public extension Traversal {
    /// Composes two traversals left-to-right: the foci of `self` are each fed into `other`,
    /// and the resulting foci are flattened. `forEach` and `modifyMut` nest, so a chain visits
    /// its leaves in one pass; `getAll` collects into a single array, appending each inner
    /// `getAll` in bulk (`[A].each` hands over its buffer).
    func compose<B>(_ other: Traversal<A, B>) -> Traversal<S, B> {
        Traversal<S, B>(
            getAll: { @Sendable s in
                var all: [B] = []
                forEach(s) { a in all.append(contentsOf: other.getAll(a)) }
                return all
            },
            forEach: { @Sendable s, body in forEach(s) { a in other.forEach(a, body) } },
            modifyMut: { @Sendable s, f in modifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }

    /// Composes a traversal with an iso. Result is a `Traversal`.
    func compose<B>(_ other: Iso<A, B>) -> Traversal<S, B> { composeSingleFocus(other.traversal) }
    /// Composes a traversal with a lens. Result is a `Traversal`.
    func compose<B>(_ other: Lens<A, B>) -> Traversal<S, B> { composeSingleFocus(other.traversal) }
    /// Composes a traversal with a prism. Result is a `Traversal`.
    func compose<B>(_ other: Prism<A, B>) -> Traversal<S, B> { composeSingleFocus(other.traversal) }
    /// Composes a traversal with an affine traversal. Result is a `Traversal`.
    func compose<B>(_ other: AffineTraversal<A, B>) -> Traversal<S, B> { composeSingleFocus(other.traversal) }

    /// `other` has at most one focus per `A`, so `getAll` appends each one as it is visited instead
    /// of building a one-element array per focus.
    private func composeSingleFocus<B>(_ other: Traversal<A, B>) -> Traversal<S, B> {
        Traversal<S, B>(
            forEach: { @Sendable s, body in forEach(s) { a in other.forEach(a, body) } },
            modifyMut: { @Sendable s, f in modifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }
}

// MARK: - {Iso, Lens, Prism, AffineTraversal} ∘ Traversal

//
// The outer optic has at most one focus, so `getAll` is the inner traversal's own bulk read of
// that focus: `lens >>> [A].each` returns the array itself.

public extension Iso {
    /// Composes an iso with a traversal. Result is a `Traversal`.
    func compose<B>(_ other: Traversal<A, B>) -> Traversal<S, B> {
        Traversal<S, B>(
            getAll: { @Sendable s in other.getAll(get(s)) },
            forEach: { @Sendable s, body in other.forEach(get(s), body) },
            modifyMut: { @Sendable s, f in modifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }
}

public extension Lens {
    /// Composes a lens with a traversal. Result is a `Traversal`.
    func compose<B>(_ other: Traversal<A, B>) -> Traversal<S, B> {
        Traversal<S, B>(
            getAll: { @Sendable s in other.getAll(get(s)) },
            forEach: { @Sendable s, body in other.forEach(get(s), body) },
            modifyMut: { @Sendable s, f in modifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }
}

public extension Prism {
    /// Composes a prism with a traversal. Result is a `Traversal`.
    func compose<B>(_ other: Traversal<A, B>) -> Traversal<S, B> {
        Traversal<S, B>(
            getAll: { @Sendable s in preview(s).map(other.getAll) ?? [] },
            forEach: { @Sendable s, body in if let a = preview(s) { other.forEach(a, body) } },
            modifyMut: { @Sendable s, f in tryModifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }
}

public extension AffineTraversal {
    /// Composes an affine traversal with a traversal. Result is a `Traversal`.
    func compose<B>(_ other: Traversal<A, B>) -> Traversal<S, B> {
        Traversal<S, B>(
            getAll: { @Sendable s in preview(s).map(other.getAll) ?? [] },
            forEach: { @Sendable s, body in if let a = preview(s) { other.forEach(a, body) } },
            modifyMut: { @Sendable s, f in tryModifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }
}
