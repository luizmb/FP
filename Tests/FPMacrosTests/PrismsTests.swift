import CoreFP
import CoreFPOperators
import FPMacros
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

private enum Reducer {
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
        #expect(optic.preview(.ok(Config(host: "localhost", port: 8_080))) == "localhost")
        #expect(optic.preview(.error("oops")) == nil)
    }

    @Test func prism_composed_with_lens_over() {
        let optic = Response.prism.ok >>> Config.lens.port
        let updated = optic.over({ $0 + 1 })(.ok(Config(host: "localhost", port: 8_080)))
        #expect(updated.ok?.port == 8_081)
    }
}

// MARK: - cases enum + is helper

@Suite("@Prisms — cases enum and is(_:)")
struct PrismsCasesEnumTests {
    @Test func cases_isCaseIterable() {
        // Generated enum conforms to CaseIterable so we can list every case once.
        #expect(Shape.cases.allCases == [.circle, .rectangle, .empty])
    }

    @Test func cases_matches_diagonal_isTrue() {
        #expect(Shape.cases.circle.matches(.circle(3.14)) == true)
        #expect(Shape.cases.rectangle.matches(.rectangle(1, 2)) == true)
        #expect(Shape.cases.empty.matches(.empty) == true)
    }

    @Test func cases_matches_offDiagonal_isFalse() {
        #expect(Shape.cases.circle.matches(.rectangle(1, 2)) == false)
        #expect(Shape.cases.rectangle.matches(.empty) == false)
        #expect(Shape.cases.empty.matches(.circle(0)) == false)
    }

    @Test func cases_matches_ignoresAssociatedPayload() {
        // Different payloads on the same case still report a match.
        #expect(Shape.cases.circle.matches(.circle(0)) == true)
        #expect(Shape.cases.circle.matches(.circle(99.99)) == true)
        #expect(Shape.cases.rectangle.matches(.rectangle(0, 0)) == true)
        #expect(Shape.cases.rectangle.matches(.rectangle(100, 200)) == true)
    }

    @Test func is_returnsTrue_whenCasesAlign() {
        #expect(Shape.circle(3.14).is(.circle) == true)
        #expect(Shape.rectangle(1, 2).is(.rectangle) == true)
        #expect(Shape.empty.is(.empty) == true)
    }

    @Test func is_returnsFalse_whenCasesDiffer() {
        #expect(Shape.circle(3.14).is(.rectangle) == false)
        #expect(Shape.circle(3.14).is(.empty) == false)
        #expect(Shape.empty.is(.circle) == false)
    }

    @Test func is_worksForLabeledParameters() {
        let b = Box.labeled(x: 1, y: 2)
        #expect(b.is(.labeled) == true)
        #expect(b.is(.wrapped) == false)
    }

    @Test func cases_worksForNestedEnum() {
        #expect(Reducer.Action.cases.allCases == [.increment, .setName, .reset])
        #expect(Reducer.Action.increment.is(.increment) == true)
        #expect(Reducer.Action.setName("hi").is(.setName) == true)
        #expect(Reducer.Action.increment.is(.reset) == false)
    }
}

// MARK: - PrismsOptions — granular emission

@Prisms(.prisms)
private enum OnlyPrisms {
    case red(Int)
    case green(String)
}

@Prisms([.prisms, .properties])
private enum PrismsAndProps {
    case wrapped(Int)
    case empty
}

@Prisms(.cases)
private enum OnlyCases {
    case alpha
    case beta(Int)
    case gamma(String, Bool)
}

// Internal-access fixture used to verify HasCases conformance can be adopted manually.
// Private/fileprivate hosts can't conform to CaseMatchable (Swift access rules around
// typealias/method visibility vs underlying type visibility), so this fixture is
// deliberately internal.
@Prisms(.cases)
enum PublicableEnum {
    case foo
    case bar(Int)
}

extension PublicableEnum: CoreFP.HasCases {
    typealias Cases = cases
}

@Suite("@Prisms — options slicing")
struct PrismsOptionsTests {
    @Test func prisms_only_emits_namespace() {
        // .prism namespace exists and works
        #expect(OnlyPrisms.prism.red.preview(.red(7)) == 7)
        #expect(OnlyPrisms.prism.green.preview(.green("hi")) == "hi")
    }

    @Test func properties_alone_promotes_prisms() {
        // [.prisms, .properties] gives both — verify .properties depends on .prisms
        #expect(PrismsAndProps.prism.wrapped.preview(.wrapped(3)) == 3)
        #expect(PrismsAndProps.wrapped(3).wrapped == 3)
        #expect(PrismsAndProps.empty.empty != nil)
    }

    @Test func cases_only_emits_cases_enum_and_is() {
        #expect(OnlyCases.cases.allCases == [.alpha, .beta, .gamma])
        #expect(OnlyCases.alpha.is(.alpha) == true)
        #expect(OnlyCases.beta(1).is(.beta) == true)
        #expect(OnlyCases.gamma("x", true).is(.gamma) == true)
        #expect(OnlyCases.alpha.is(.beta) == false)
    }

    @Test func hasCases_protocol_can_be_adopted_manually() {
        // The macro doesn't auto-add HasCases conformance (Swift extension-macro role
        // can't reach private nested types). Users can opt in manually.
        func firstIsHit<T: CoreFP.HasCases>(_ v: T) -> Bool {
            v.is(T.Cases.allCases.first.unsafelyUnwrapped)
        }
        #expect(firstIsHit(PublicableEnum.foo) == true)
        #expect(firstIsHit(PublicableEnum.bar(1)) == false)
    }
}
