import CoreFP
import Testing

@Suite("Optional — prism + HasCases")
struct OptionalPrismTests {
    @Test func prism_some_preview_hit() {
        let s: Int? = 42
        #expect(Int?.prism.some.preview(s) == 42)
    }

    @Test func prism_some_preview_miss() {
        let n: Int? = nil
        #expect(Int?.prism.some.preview(n) == nil)
    }

    @Test func prism_none_preview_hit() {
        let n: Int? = nil
        #expect(Int?.prism.none.preview(n) != nil)
    }

    @Test func prism_none_preview_miss() {
        let s: Int? = 42
        #expect(Int?.prism.none.preview(s) == nil)
    }

    @Test func prism_some_review() {
        let constructed: Int? = Int?.prism.some.review(7)
        #expect(constructed == 7)
    }

    @Test func prism_none_review() {
        let constructed: Int? = Int?.prism.none.review(())
        #expect(constructed == nil)
    }

    @Test func cases_isCaseIterable() {
        #expect(Int?.Cases.allCases == [.some, .none])
    }

    @Test func is_returnsTrue_whenAligned() {
        let s: Int? = 42
        let n: Int? = nil
        #expect(s.is(.some))
        #expect(n.is(.none))
    }

    @Test func is_returnsFalse_whenMisaligned() {
        let s: Int? = 42
        let n: Int? = nil
        #expect(!s.is(.none))
        #expect(!n.is(.some))
    }
}
