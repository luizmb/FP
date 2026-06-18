// SPDX-License-Identifier: Apache-2.0
import CoreFP
@testable import CoreFPOperators
import Testing

// MARK: - Fixtures

private let addOne = iso(get: { $0 + 1 }, reverseGet: { $0 - 1 }) // Iso<Int, Int>
private let timesTwo = iso(get: { $0 * 2 }, reverseGet: { $0 / 2 }) // Iso<Int, Int>

private struct Box: Equatable { var value: Int }
private let boxValueLens: Lens<Box, Int> = lens(\.value)

private enum Tag: Equatable { case tagged(Int); case untagged }
private let taggedPrism: Prism<Tag, Int> = prism(
    preview: { if case let .tagged(n) = $0 { n } else { nil } },
    review: Tag.tagged
)
private let taggedAT: AffineTraversal<Tag, Int> = AffineTraversal(
    preview: { if case let .tagged(n) = $0 { n } else { nil } },
    set: { s, n in if case .tagged = s { .tagged(n) } else { s } }
)

// MARK: - Iso >>> Iso

@Suite struct IsoIsoCompositionTests {
    @Test func forwardGet() {
        let composed = addOne >>> timesTwo // get = +1 then *2
        #expect(composed.get(5) == 12) // (5+1)*2 = 12
    }

    @Test func forwardReverseGet() {
        let composed = addOne >>> timesTwo
        #expect(composed.reverseGet(12) == 5) // 12/2 - 1 = 5
    }

    @Test func forwardRoundTrip() {
        let composed = addOne >>> timesTwo
        let s = 7
        #expect(composed.reverseGet(composed.get(s)) == s)
    }

    @Test func backwardGet() {
        let composed = timesTwo <<< addOne // same as addOne >>> timesTwo
        #expect(composed.get(5) == 12)
    }

    @Test func backwardReverseGet() {
        let composed = timesTwo <<< addOne
        #expect(composed.reverseGet(12) == 5)
    }
}

// MARK: - Iso >>> Lens

@Suite struct IsoLensCompositionTests {
    private let doubleBoxIso = iso(
        get: { Box(value: $0.value * 2) },
        reverseGet: { Box(value: $0.value / 2) }
    )

    @Test func isoThenLens_get() {
        let composed: Lens<Box, Int> = doubleBoxIso >>> boxValueLens
        #expect(composed.get(Box(value: 3)) == 6) // value*2 = 6
    }

    @Test func isoThenLens_set() {
        let composed: Lens<Box, Int> = doubleBoxIso >>> boxValueLens
        let result = composed.set(Box(value: 99), 10)
        #expect(composed.get(result) == 10)
    }

    @Test func backward_isoThenLens() {
        let forward: Lens<Box, Int> = doubleBoxIso >>> boxValueLens
        let backward: Lens<Box, Int> = boxValueLens <<< doubleBoxIso
        #expect(forward.get(Box(value: 3)) == backward.get(Box(value: 3)))
    }
}

// MARK: - Lens >>> Iso

@Suite struct LensIsoCompositionTests {
    @Test func lensThenIso_get() {
        let composed: Lens<Box, Int> = boxValueLens >>> addOne
        #expect(composed.get(Box(value: 5)) == 6)
    }

    @Test func lensThenIso_set() {
        let composed: Lens<Box, Int> = boxValueLens >>> addOne
        // set 10 → reverseGet(10)=9, lens sets value=9
        let result = composed.set(Box(value: 5), 10)
        #expect(result.value == 9)
    }

    @Test func backward_lensThenIso() {
        let forward: Lens<Box, Int> = boxValueLens >>> addOne
        let backward: Lens<Box, Int> = addOne <<< boxValueLens
        #expect(forward.get(Box(value: 5)) == backward.get(Box(value: 5)))
    }
}

// MARK: - Iso >>> Prism

@Suite struct IsoPrismCompositionTests {
    // A prism that only focuses on non-negative ints
    private let nonNegPrism: Prism<Int, Int> = prism(
        preview: { $0 >= 0 ? $0 : nil },
        review: { $0 }
    )

    @Test func isoThenPrism_preview_succeeds() {
        let composed: Prism<Int, Int> = addOne >>> nonNegPrism
        #expect(composed.preview(5) == .some(6)) // 5+1=6, >=0 ✓
    }

    @Test func isoThenPrism_preview_fails() {
        let composed: Prism<Int, Int> = addOne >>> nonNegPrism
        #expect(composed.preview(-2) == .none) // -2+1=-1, <0 ✗
    }

    @Test func isoThenPrism_review() {
        let composed: Prism<Int, Int> = addOne >>> nonNegPrism
        // review: prism.review(6)=6, iso.reverseGet(6)=5
        #expect(composed.review(6) == 5)
    }

    @Test func backward_isoPrism() {
        let forward: Prism<Int, Int> = addOne >>> nonNegPrism
        let backward: Prism<Int, Int> = nonNegPrism <<< addOne
        #expect(forward.preview(5) == backward.preview(5))
        #expect(forward.preview(-2) == backward.preview(-2))
    }
}

// MARK: - Prism >>> Iso

@Suite struct PrismIsoCompositionTests {
    @Test func prismThenIso_preview() {
        let composed: Prism<Tag, Int> = taggedPrism >>> addOne
        #expect(composed.preview(.tagged(5)) == .some(6))
        #expect(composed.preview(.untagged) == .none)
    }

    @Test func prismThenIso_review() {
        let composed: Prism<Tag, Int> = taggedPrism >>> addOne
        // review: iso.reverseGet(6)=5, prism.review(5)=.tagged(5)
        #expect(composed.review(6) == .tagged(5))
    }

    @Test func backward_prismIso() {
        let forward: Prism<Tag, Int> = taggedPrism >>> addOne
        let backward: Prism<Tag, Int> = addOne <<< taggedPrism
        #expect(forward.preview(.tagged(3)) == backward.preview(.tagged(3)))
        #expect(forward.preview(.untagged) == backward.preview(.untagged))
    }
}

// MARK: - AffineTraversal >>> Iso

@Suite struct AffineTraversalIsoCompositionTests {
    @Test func affineTraversalThenIso_preview() {
        let composed: AffineTraversal<Tag, Int> = taggedAT >>> addOne
        #expect(composed.preview(.tagged(5)) == .some(6))
        #expect(composed.preview(.untagged) == .none)
    }

    @Test func affineTraversalThenIso_set() {
        let composed: AffineTraversal<Tag, Int> = taggedAT >>> addOne
        // set 10 → iso.reverseGet(10)=9, AT.set(.tagged(5), 9)=.tagged(9)
        #expect(composed.set(.tagged(5), 10) == .tagged(9))
        #expect(composed.set(.untagged, 10) == .untagged)
    }

    @Test func backward_affineTraversalIso() {
        let forward: AffineTraversal<Tag, Int> = taggedAT >>> addOne
        let backward: AffineTraversal<Tag, Int> = addOne <<< taggedAT
        #expect(forward.preview(.tagged(5)) == backward.preview(.tagged(5)))
        #expect(forward.preview(.untagged) == backward.preview(.untagged))
    }
}

// MARK: - Iso >>> AffineTraversal

@Suite struct IsoAffineTraversalCompositionTests {
    private let positivePrismAT: AffineTraversal<Int, Int> = AffineTraversal(
        preview: { $0 > 0 ? $0 : nil },
        set: { _, a in a }
    )

    @Test func isoThenAffineTraversal_preview_succeeds() {
        let composed: AffineTraversal<Int, Int> = addOne >>> positivePrismAT
        #expect(composed.preview(0) == .some(1)) // 0+1=1 > 0 ✓
    }

    @Test func isoThenAffineTraversal_preview_fails() {
        let composed: AffineTraversal<Int, Int> = addOne >>> positivePrismAT
        #expect(composed.preview(-2) == .none) // -2+1=-1, not > 0 ✗
    }

    @Test func backward_isoAffineTraversal() {
        let forward: AffineTraversal<Int, Int> = addOne >>> positivePrismAT
        let backward: AffineTraversal<Int, Int> = positivePrismAT <<< addOne
        #expect(forward.preview(0) == backward.preview(0))
        #expect(forward.preview(-2) == backward.preview(-2))
    }
}
