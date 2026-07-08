// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

private struct MyError: Error, Equatable { let code: Int }

@Suite("Result — prism + HasCases")
struct ResultPrismTests {
    @Test func prism_success_preview_hit() {
        let r: Result<Int, MyError> = .success(42)
        #expect(Result<Int, MyError>.prism.success.preview(r) == 42)
    }

    @Test func prism_success_preview_miss() {
        let r: Result<Int, MyError> = .failure(.init(code: 1))
        #expect(Result<Int, MyError>.prism.success.preview(r) == nil)
    }

    @Test func prism_failure_preview_hit() {
        let r: Result<Int, MyError> = .failure(.init(code: 9))
        #expect(Result<Int, MyError>.prism.failure.preview(r) == .init(code: 9))
    }

    @Test func prism_failure_preview_miss() {
        let r: Result<Int, MyError> = .success(0)
        #expect(Result<Int, MyError>.prism.failure.preview(r) == nil)
    }

    @Test func prism_success_review_reconstructs() {
        let r: Result<Int, MyError> = Result.prism.success.review(7)
        #expect(r == .success(7))
    }

    @Test func prism_failure_review_reconstructs() {
        let r: Result<Int, MyError> = Result.prism.failure.review(.init(code: 5))
        #expect(r == .failure(.init(code: 5)))
    }

    @Test func cases_isCaseIterable() {
        #expect(Result<Int, MyError>.Cases.allCases == [.success, .failure])
    }

    @Test func is_returnsTrue_whenAligned() {
        let ok: Result<Int, MyError> = .success(1)
        let bad: Result<Int, MyError> = .failure(.init(code: 1))
        #expect(ok.is(.success))
        #expect(bad.is(.failure))
    }

    @Test func is_returnsFalse_whenMisaligned() {
        let ok: Result<Int, MyError> = .success(1)
        let bad: Result<Int, MyError> = .failure(.init(code: 1))
        #expect(!ok.is(.failure))
        #expect(!bad.is(.success))
    }

    @Test func success_property_hit() {
        let r: Result<Int, MyError> = .success(42)
        #expect(r.success == 42)
    }

    @Test func success_property_miss() {
        let r: Result<Int, MyError> = .failure(.init(code: 1))
        #expect(r.success == nil)
    }

    @Test func failure_property_hit() {
        let r: Result<Int, MyError> = .failure(.init(code: 9))
        #expect(r.failure == .init(code: 9))
    }

    @Test func failure_property_miss() {
        let r: Result<Int, MyError> = .success(0)
        #expect(r.failure == nil)
    }
}
