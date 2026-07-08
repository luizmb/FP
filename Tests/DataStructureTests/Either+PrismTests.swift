// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite("Either — prism + HasCases + case key paths")
struct EitherPrismTests {
    @Test func prism_left_preview_hit() {
        let e: Either<String, Int> = .left("oops")
        #expect(Either<String, Int>.prism.left.preview(e) == "oops")
    }

    @Test func prism_left_preview_miss() {
        let e: Either<String, Int> = .right(42)
        #expect(Either<String, Int>.prism.left.preview(e) == nil)
    }

    @Test func prism_right_preview_hit() {
        let e: Either<String, Int> = .right(42)
        #expect(Either<String, Int>.prism.right.preview(e) == 42)
    }

    @Test func prism_review_reconstructs() {
        let l: Either<String, Int> = Either.prism.left.review("x")
        let r: Either<String, Int> = Either.prism.right.review(9)
        #expect(l == .left("x"))
        #expect(r == .right(9))
    }

    @Test func caseKeyPath_recoversPrism() {
        let prism = Prism(\.left as PrismKeyPath<Either<String, Int>, String>)
        #expect(prism.preview(.left("oops")) == "oops")
        #expect(prism.preview(.right(42)) == nil)
    }

    @Test func cases_isCaseIterable() {
        #expect(Either<String, Int>.Cases.allCases == [.left, .right])
    }

    @Test func is_returnsTrue_whenAligned() {
        let l: Either<String, Int> = .left("oops")
        let r: Either<String, Int> = .right(42)
        #expect(l.is(.left))
        #expect(r.is(.right))
    }

    @Test func is_returnsFalse_whenMisaligned() {
        let l: Either<String, Int> = .left("oops")
        #expect(!l.is(.right))
    }

    @Test func left_property_hit() {
        let e: Either<String, Int> = .left("oops")
        #expect(e.left == "oops")
    }

    @Test func left_property_miss() {
        let e: Either<String, Int> = .right(42)
        #expect(e.left == nil)
    }

    @Test func right_property_hit() {
        let e: Either<String, Int> = .right(42)
        #expect(e.right == 42)
    }

    @Test func right_property_miss() {
        let e: Either<String, Int> = .left("oops")
        #expect(e.right == nil)
    }
}
