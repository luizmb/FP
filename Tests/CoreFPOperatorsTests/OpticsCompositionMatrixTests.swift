// SPDX-License-Identifier: Apache-2.0
import CoreFP
@testable import CoreFPOperators
import Testing

// MARK: - Optic composition completeness matrix

//
// Every ordered pair of the five optics — Iso, Lens, Prism, AffineTraversal,
// Traversal — must compose, in all three forms (`.compose`, `>>>`, `<<<`), and
// land on the correct result type. Each line below pins the result to an explicit
// concrete type, so a MISSING or WRONG-TYPED combo is a *compile error*, not a
// silent gap. This is the guard against forgetting a cell (as Iso once was).
//
// Result-type lattice (result = the weakest of the two; Lens ∨ Prism = Affine):
//
//   LHS \ RHS: Iso, Lens, Prism, Affine, Traversal
//   Iso        → Iso, Lens, Prism, Affine, Traversal
//   Lens       → Lens, Lens, Affine, Affine, Traversal
//   Prism      → Prism, Affine, Prism, Affine, Traversal
//   Affine     → Affine, Affine, Affine, Affine, Traversal
//   Traversal  → Traversal (every combo)

private let i: Iso<Int, Int> = iso(get: { $0 }, reverseGet: { $0 })
private let l: Lens<Int, Int> = lens(\.self)
private let p: Prism<Int, Int> = prism(preview: { $0 }, review: { $0 })
private let a: AffineTraversal<Int, Int> = .id
private let t: Traversal<Int, Int> = .id

@Suite("Optic composition completeness matrix")
struct OpticsCompositionMatrixTests {
    // MARK: `.compose` — all 25 pairs, result types pinned

    @Test func composeNamedCoversEveryPair() {
        let _: Iso<Int, Int> = i.compose(i)
        let _: Lens<Int, Int> = i.compose(l)
        let _: Prism<Int, Int> = i.compose(p)
        let _: AffineTraversal<Int, Int> = i.compose(a)
        let _: Traversal<Int, Int> = i.compose(t)

        let _: Lens<Int, Int> = l.compose(i)
        let _: Lens<Int, Int> = l.compose(l)
        let _: AffineTraversal<Int, Int> = l.compose(p)
        let _: AffineTraversal<Int, Int> = l.compose(a)
        let _: Traversal<Int, Int> = l.compose(t)

        let _: Prism<Int, Int> = p.compose(i)
        let _: AffineTraversal<Int, Int> = p.compose(l)
        let _: Prism<Int, Int> = p.compose(p)
        let _: AffineTraversal<Int, Int> = p.compose(a)
        let _: Traversal<Int, Int> = p.compose(t)

        let _: AffineTraversal<Int, Int> = a.compose(i)
        let _: AffineTraversal<Int, Int> = a.compose(l)
        let _: AffineTraversal<Int, Int> = a.compose(p)
        let _: AffineTraversal<Int, Int> = a.compose(a)
        let _: Traversal<Int, Int> = a.compose(t)

        let _: Traversal<Int, Int> = t.compose(i)
        let _: Traversal<Int, Int> = t.compose(l)
        let _: Traversal<Int, Int> = t.compose(p)
        let _: Traversal<Int, Int> = t.compose(a)
        let _: Traversal<Int, Int> = t.compose(t)
        #expect(Bool(true))
    }

    // MARK: `>>>` — all 25 pairs, result types pinned

    @Test func forwardOperatorCoversEveryPair() {
        let _: Iso<Int, Int> = i >>> i
        let _: Lens<Int, Int> = i >>> l
        let _: Prism<Int, Int> = i >>> p
        let _: AffineTraversal<Int, Int> = i >>> a
        let _: Traversal<Int, Int> = i >>> t

        let _: Lens<Int, Int> = l >>> i
        let _: Lens<Int, Int> = l >>> l
        let _: AffineTraversal<Int, Int> = l >>> p
        let _: AffineTraversal<Int, Int> = l >>> a
        let _: Traversal<Int, Int> = l >>> t

        let _: Prism<Int, Int> = p >>> i
        let _: AffineTraversal<Int, Int> = p >>> l
        let _: Prism<Int, Int> = p >>> p
        let _: AffineTraversal<Int, Int> = p >>> a
        let _: Traversal<Int, Int> = p >>> t

        let _: AffineTraversal<Int, Int> = a >>> i
        let _: AffineTraversal<Int, Int> = a >>> l
        let _: AffineTraversal<Int, Int> = a >>> p
        let _: AffineTraversal<Int, Int> = a >>> a
        let _: Traversal<Int, Int> = a >>> t

        let _: Traversal<Int, Int> = t >>> i
        let _: Traversal<Int, Int> = t >>> l
        let _: Traversal<Int, Int> = t >>> p
        let _: Traversal<Int, Int> = t >>> a
        let _: Traversal<Int, Int> = t >>> t
        #expect(Bool(true))
    }

    // MARK: `<<<` — all 25 pairs (reversed), result types pinned

    @Test func backwardOperatorCoversEveryPair() {
        let _: Iso<Int, Int> = i <<< i
        let _: Lens<Int, Int> = l <<< i
        let _: Prism<Int, Int> = p <<< i
        let _: AffineTraversal<Int, Int> = a <<< i
        let _: Traversal<Int, Int> = t <<< i

        let _: Lens<Int, Int> = i <<< l
        let _: Lens<Int, Int> = l <<< l
        let _: AffineTraversal<Int, Int> = p <<< l
        let _: AffineTraversal<Int, Int> = a <<< l
        let _: Traversal<Int, Int> = t <<< l

        let _: Prism<Int, Int> = i <<< p
        let _: AffineTraversal<Int, Int> = l <<< p
        let _: Prism<Int, Int> = p <<< p
        let _: AffineTraversal<Int, Int> = a <<< p
        let _: Traversal<Int, Int> = t <<< p

        let _: AffineTraversal<Int, Int> = i <<< a
        let _: AffineTraversal<Int, Int> = l <<< a
        let _: AffineTraversal<Int, Int> = p <<< a
        let _: AffineTraversal<Int, Int> = a <<< a
        let _: Traversal<Int, Int> = t <<< a

        let _: Traversal<Int, Int> = i <<< t
        let _: Traversal<Int, Int> = l <<< t
        let _: Traversal<Int, Int> = p <<< t
        let _: Traversal<Int, Int> = a <<< t
        let _: Traversal<Int, Int> = t <<< t
        #expect(Bool(true))
    }
}
