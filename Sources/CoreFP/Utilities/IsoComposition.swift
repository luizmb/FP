// SPDX-License-Identifier: Apache-2.0

// MARK: - Iso composition — named functions

//
// `Iso` is the strongest optic, so composing it with anything yields the
// *other* optic's type (an iso only refines a focus losslessly):
//
//   - Iso ∘ Iso              → Iso
//   - Iso ∘ {Lens, Prism, AffineTraversal, Traversal} → that same kind
//   - {Lens, Prism, AffineTraversal, Traversal} ∘ Iso → that same kind
//
// Every mixed combo is expressed by converting the iso to the matching optic
// (`asLens` / `asPrism` / `asAffineTraversal` / `.traversal`) and delegating to
// the existing composition. The `>>>` / `<<<` operators in CoreFPOperators
// mirror these; CoreFP-only callers use these named `compose` methods.
//
// (Iso ∘ Traversal and Traversal ∘ Iso live in TraversalComposition.swift,
// alongside the rest of the Traversal row/column.)

public extension Iso {
    /// Composes two isos left-to-right, yielding a lossless `Iso<S, B>`.
    func compose<B>(_ other: Iso<A, B>) -> Iso<S, B> {
        Iso<S, B>(
            get: { @Sendable s in other.get(get(s)) },
            reverseGet: { @Sendable b in reverseGet(other.reverseGet(b)) }
        )
    }

    /// Composes an iso with a lens, yielding a `Lens<S, B>`.
    func compose<B>(_ other: Lens<A, B>) -> Lens<S, B> { asLens.compose(other) }
    /// Composes an iso with a prism, yielding a `Prism<S, B>`.
    func compose<B>(_ other: Prism<A, B>) -> Prism<S, B> { asPrism.compose(other) }
    /// Composes an iso with an affine traversal, yielding an `AffineTraversal<S, B>`.
    func compose<B>(_ other: AffineTraversal<A, B>) -> AffineTraversal<S, B> { asAffineTraversal.compose(other) }
}

// MARK: - {Lens, Prism, AffineTraversal} ∘ Iso

public extension Lens {
    /// Composes a lens with an iso, yielding a `Lens<S, B>`.
    func compose<B>(_ other: Iso<A, B>) -> Lens<S, B> { compose(other.asLens) }
}

public extension Prism {
    /// Composes a prism with an iso, yielding a `Prism<S, B>`.
    func compose<B>(_ other: Iso<A, B>) -> Prism<S, B> { compose(other.asPrism) }
}

public extension AffineTraversal {
    /// Composes an affine traversal with an iso, yielding an `AffineTraversal<S, B>`.
    func compose<B>(_ other: Iso<A, B>) -> AffineTraversal<S, B> { compose(other.asAffineTraversal) }
}
