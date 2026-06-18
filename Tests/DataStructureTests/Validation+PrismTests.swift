// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite("Validation — prism + HasCases + case key paths")
struct ValidationPrismTests {
    @Test func prism_success_preview_hit() {
        let v: Validation<String, Int> = .success(42)
        #expect(Validation<String, Int>.prism.success.preview(v) == 42)
    }

    @Test func prism_success_preview_miss() {
        let v: Validation<String, Int> = .failure("err")
        #expect(Validation<String, Int>.prism.success.preview(v) == nil)
    }

    @Test func prism_failure_preview_hit() {
        let v: Validation<String, Int> = .failure("oops")
        #expect(Validation<String, Int>.prism.failure.preview(v) == "oops")
    }

    @Test func prism_review_reconstructs() {
        let s: Validation<String, Int> = Validation.prism.success.review(7)
        let f: Validation<String, Int> = Validation.prism.failure.review("x")
        #expect(s == .success(7))
        #expect(f == .failure("x"))
    }

    @Test func caseKeyPath_recoversPrism() {
        let prism = Prism(\.success as PrismKeyPath<Validation<String, Int>, Int>)
        #expect(prism.preview(.success(42)) == 42)
        #expect(prism.preview(.failure("err")) == nil)
    }

    @Test func cases_isCaseIterable() {
        #expect(Validation<String, Int>.Cases.allCases == [.failure, .success])
    }

    @Test func is_returnsTrue_whenAligned() {
        let s: Validation<String, Int> = .success(1)
        let f: Validation<String, Int> = .failure("x")
        #expect(s.is(.success))
        #expect(f.is(.failure))
    }
}
