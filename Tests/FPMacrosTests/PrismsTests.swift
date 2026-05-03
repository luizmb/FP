import FPMacros
import CoreFP
import CoreFPOperators
import Testing

// MARK: - Fixtures
// @attached(member) works at any nesting level

@Prisms
private enum Shape {
    case circle(Double)
    case rectangle(Double, Double)
    case empty
}

@Prisms
private enum Box {
    case wrapped(String)
    case labeled(x: Int, y: Int)
}

// MARK: - Nesting works

private struct Reducer {
    @Lenses(init: .internal)
    struct State {
        let name: String
        var count: Int
    }

    @Prisms
    enum Action {
        case increment
        case setName(String)
        case reset
    }
}

// MARK: - Computed property extraction

@Suite("@Prisms — computed property extraction")
struct PrismsExtractionTests {
    @Test func extracts_matching_single_case() {
        #expect(Shape.circle(3.14).circle == 3.14)
    }

    @Test func returns_nil_for_non_matching_case() {
        #expect(Shape.circle(3.14).empty == nil)
    }

    @Test func extracts_tuple_case_components() {
        let s = Shape.rectangle(2.0, 4.0)
        #expect(s.rectangle?.0 == 2.0)
        #expect(s.rectangle?.1 == 4.0)
    }

    @Test func extracts_void_case() {
        #expect(Shape.empty.empty != nil)
    }

    @Test func extracts_labeled_tuple_case() {
        let b = Box.labeled(x: 1, y: 2)
        #expect(b.labeled?.0 == 1)
        #expect(b.labeled?.1 == 2)
    }

    @Test func works_for_nested_enum() {
        #expect(Reducer.Action.increment.increment != nil)
        #expect(Reducer.Action.setName("hi").setName == "hi")
        #expect(Reducer.Action.increment.setName == nil)
    }
}

// MARK: - Prism namespace

@Suite("@Prisms — prism namespace")
struct PrismsNamespaceTests {
    @Test func preview_hit() {
        #expect(Shape.prism.circle.preview(.circle(3.14)) == 3.14)
    }

    @Test func preview_miss() {
        #expect(Shape.prism.circle.preview(.rectangle(1, 2)) == nil)
    }

    @Test func review_reconstructs() {
        guard case .circle(let r) = Shape.prism.circle.review(5.0) else {
            Issue.record("Expected .circle"); return
        }
        #expect(r == 5.0)
    }

    @Test func set_changes_associated_value() {
        #expect(Shape.prism.circle.set(.circle(3.14), 5.0).circle == 5.0)
    }

    @Test func set_on_wrong_case_is_noop() {
        let updated = Shape.prism.circle.set(.rectangle(1, 2), 5.0)
        #expect(updated.rectangle?.0 == 1.0)
    }

    @Test func over_transforms_matching_case() {
        #expect(Shape.prism.circle.over({ $0 * 2 })(.circle(3.14)).circle == 6.28)
    }

    @Test func over_is_noop_on_wrong_case() {
        #expect(Shape.prism.circle.over({ $0 * 2 })(.empty).empty != nil)
    }

    @Test func namespace_works_for_nested_enum() {
        let a = Reducer.Action.setName("hello")
        #expect(Reducer.Action.prism.setName.preview(a) == "hello")
    }
}

// MARK: - Prism laws

@Suite("@Prisms — laws")
struct PrismsLawTests {
    @Test("preview-review: extracting from a reviewed value returns the original")
    func law_previewReview() {
        #expect(Shape.prism.circle.preview(Shape.prism.circle.review(3.14)) == 3.14)
    }

    @Test("set-preview: set then preview returns the new value")
    func law_setPreview() {
        #expect(Shape.prism.circle.preview(Shape.prism.circle.set(.circle(1.0), 9.0)) == 9.0)
    }

    @Test("set-set: last set wins")
    func law_setSet() {
        let s = Shape.circle(1.0)
        let once  = Shape.prism.circle.set(Shape.prism.circle.set(s, 2.0), 3.0)
        let twice = Shape.prism.circle.set(s, 3.0)
        #expect(once.circle == twice.circle)
    }
}

// MARK: - Composition

@Suite("@Prisms — composition with other optics")
struct PrismsCompositionTests {
    @Lenses(init: .internal)
    private struct Config {
        let host: String
        var port: Int
    }

    @Prisms
    private enum Response {
        case ok(Config)
        case error(String)
    }

    @Test func prism_composed_with_lens_preview() {
        let optic = Response.prism.ok >>> Config.lens.host
        #expect(optic.preview(.ok(Config(host: "localhost", port: 8080))) == "localhost")
        #expect(optic.preview(.error("oops")) == nil)
    }

    @Test func prism_composed_with_lens_over() {
        let optic = Response.prism.ok >>> Config.lens.port
        let updated = optic.over({ $0 + 1 })(.ok(Config(host: "localhost", port: 8080)))
        #expect(updated.ok?.port == 8081)
    }
}
