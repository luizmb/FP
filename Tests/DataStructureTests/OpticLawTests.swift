// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// Property-based optic laws, complementing the example-based `OpticsTests` in CoreFPTests. Each
// law is checked over 300 generated inputs and replays from its seed on failure.

private let intGen = Gen.int(in: -20...20)

private struct Pair: Equatable, Sendable { var first: Int; var second: Int }
private let pairGen: Gen<Pair> = Gen.zip(intGen, intGen).map { pair in
    let (a, b) = pair
    return Pair(first: a, second: b)
}

private struct Box: Equatable, Sendable { var maybe: Int? }
private let boxGen: Gen<Box> = intGen.optional().map { Box(maybe: $0) }

private let eitherGen: Gen<Either<Int, String>> = Gen.one(of: NonEmpty(
    head: intGen.map { Either<Int, String>.left($0) },
    tail: [Gen.string(of: .letter(), count: Gen.int(in: 0...4)).map { Either<Int, String>.right($0) }]
))

private let intFuncGen: Gen<@Sendable (Int) -> Int> = Gen.zip(Gen.int(in: -3...3), Gen.int(in: -3...3)).map { pair in
    let (a, b) = pair
    return { $0 &* a &+ b }
}

@Suite("Lens — laws")
struct LensLawTests {
    private let lens = CoreFP.lens(\Pair.first)

    @Test func getSet() { // setting what you got changes nothing
        forAll(pairGen) { s in lens.set(s, lens.get(s)) == s }
    }

    @Test func setGet() { // getting after setting returns what you set
        forAll(pairGen, intGen) { s, a in lens.get(lens.set(s, a)) == a }
    }

    @Test func setSet() { // last set wins
        forAll(pairGen, intGen, intGen) { s, a1, a2 in
            lens.set(lens.set(s, a1), a2) == lens.set(s, a2)
        }
    }
}

@Suite("Prism — laws")
struct PrismLawTests {
    private let prism = Either<Int, String>.prism.left

    @Test func reviewThenPreviewRoundTrips() {
        forAll(intGen) { a in prism.preview(prism.review(a)) == a }
    }

    @Test func previewThenReviewReconstructs() { // when it matches, review rebuilds the original
        forAll(eitherGen) { s in
            guard let a = prism.preview(s) else { return true }
            return prism.review(a) == s
        }
    }
}

@Suite("AffineTraversal — laws")
struct AffineTraversalLawTests {
    private let affine = affineTraversal(\Box.maybe)

    @Test func setThenPreview() { // set writes the focus (unconditionally for an optional key path)
        forAll(boxGen, intGen) { s, a in affine.preview(affine.set(s, a)) == a }
    }

    @Test func setWhatYouPreview() { // setting back the previewed value is identity
        forAll(boxGen) { s in
            guard let a = affine.preview(s) else { return true }
            return affine.set(s, a) == s
        }
    }

    @Test func setSet() {
        forAll(boxGen, intGen, intGen) { s, a1, a2 in
            affine.set(affine.set(s, a1), a2) == affine.set(s, a2)
        }
    }

    @Test func overIsNoOpWhenFocusAbsent() { // the "affine" part: no focus → over leaves S unchanged
        forAll(boxGen, intFuncGen) { s, f in
            affine.preview(s) != nil || affine.over(f)(s) == s
        }
    }
}

@Suite("Iso — laws")
struct IsoLawTests {
    private let iso = Iso<Int, Int>(get: { -$0 }, reverseGet: { -$0 })

    @Test func getThenReverseGet() {
        forAll(intGen) { s in iso.reverseGet(iso.get(s)) == s }
    }

    @Test func reverseGetThenGet() {
        forAll(intGen) { a in iso.get(iso.reverseGet(a)) == a }
    }
}
