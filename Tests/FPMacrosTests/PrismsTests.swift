// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import FPMacros
import Testing

// MARK: - Fixtures
// @attached(member) works at any nesting level

@Prisms
fileprivate enum Shape {
    case circle(Double)
    case rectangle(Double, Double)
    case empty
}

@Prisms
fileprivate enum Box {
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
        #expect(Shape.prism.circle.preview(Shape.prism.circle.set(.circle(3.14), 5.0)) == 5.0)
    }

    @Test func set_on_wrong_case_is_noop() {
        let updated = Shape.prism.circle.set(.rectangle(1, 2), 5.0)
        #expect(Shape.prism.rectangle.preview(updated)?.0 == 1.0)
    }

    @Test func over_transforms_matching_case() {
        #expect(Shape.prism.circle.preview(Shape.prism.circle.over({ $0 * 2 })(.circle(3.14))) == 6.28)
    }

    @Test func over_is_noop_on_wrong_case() {
        #expect(Shape.prism.circle.over({ $0 * 2 })(.empty).is(.empty))
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
        let once = Shape.prism.circle.set(Shape.prism.circle.set(s, 2.0), 3.0)
        let twice = Shape.prism.circle.set(s, 3.0)
        #expect(Shape.prism.circle.preview(once) == Shape.prism.circle.preview(twice))
    }
}

// MARK: - Composition

@Suite("@Prisms — composition with other optics")
struct PrismsCompositionTests {
    @Lenses(init: .internal)
    fileprivate struct Config {
        let host: String
        var port: Int
    }

    @Prisms
    fileprivate enum Response {
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
        #expect(Response.prism.ok.preview(updated)?.port == 8_081)
    }
}

// MARK: - cases enum + is helper

@Suite("@Prisms — cases enum and is(_:)")
struct PrismsCasesEnumTests {
    @Test func cases_isCaseIterable() {
        // Generated enum conforms to CaseIterable so we can list every case once.
        #expect(Shape.Cases.allCases == [.circle, .rectangle, .empty])
    }

    @Test func cases_matches_diagonal_isTrue() {
        #expect(Shape.Cases.circle.matches(.circle(3.14)) == true)
        #expect(Shape.Cases.rectangle.matches(.rectangle(1, 2)) == true)
        #expect(Shape.Cases.empty.matches(.empty) == true)
    }

    @Test func cases_matches_offDiagonal_isFalse() {
        #expect(Shape.Cases.circle.matches(.rectangle(1, 2)) == false)
        #expect(Shape.Cases.rectangle.matches(.empty) == false)
        #expect(Shape.Cases.empty.matches(.circle(0)) == false)
    }

    @Test func cases_matches_ignoresAssociatedPayload() {
        // Different payloads on the same case still report a match.
        #expect(Shape.Cases.circle.matches(.circle(0)) == true)
        #expect(Shape.Cases.circle.matches(.circle(99.99)) == true)
        #expect(Shape.Cases.rectangle.matches(.rectangle(0, 0)) == true)
        #expect(Shape.Cases.rectangle.matches(.rectangle(100, 200)) == true)
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
        #expect(Reducer.Action.Cases.allCases == [.increment, .setName, .reset])
        #expect(Reducer.Action.increment.is(.increment) == true)
        #expect(Reducer.Action.setName("hi").is(.setName) == true)
        #expect(Reducer.Action.increment.is(.reset) == false)
    }
}

// MARK: - PrismsOptions — granular emission

@Prisms(.prisms)
fileprivate enum OnlyPrisms {
    case red(Int)
    case green(String)
}

@Prisms(.cases)
fileprivate enum OnlyCases {
    case alpha
    case beta(Int)
    case gamma(String, Bool)
}

// Internal-access fixture used to verify HasCases conformance can be adopted manually
// (the macro doesn't add it automatically because `@attached(extension)` can't reach
// nested fileprivate hosts at file scope).
@Prisms(.cases)
enum PublicableEnum {
    case foo
    case bar(Int)
}

// The nested `Cases` enum's name matches the protocol's `associatedtype Cases`, so
// Swift infers the conformance without an explicit typealias.
extension PublicableEnum: CoreFP.HasCases {}

@Prisms
fileprivate enum Pixel {
    case rgb(red: Int, green: Int, blue: Int)
    case gray(Int)
    case transparent
}

// Generic fixture — verifies `static var prism` fallback works.
@Prisms
fileprivate enum Wrapped<A> {
    case some(A)
    case none
}

@Suite("@Prisms — options slicing")
struct PrismsOptionsTests {
    @Test func prisms_only_emits_namespace() {
        #expect(OnlyPrisms.prism.red.preview(.red(7)) == 7)
        #expect(OnlyPrisms.prism.green.preview(.green("hi")) == "hi")
    }

    @Test func cases_only_emits_cases_enum_and_is() {
        #expect(OnlyCases.Cases.allCases == [.alpha, .beta, .gamma])
        #expect(OnlyCases.alpha.is(.alpha) == true)
        #expect(OnlyCases.beta(1).is(.beta) == true)
        #expect(OnlyCases.gamma("x", true).is(.gamma) == true)
        #expect(OnlyCases.alpha.is(.beta) == false)
    }

    @Test func prism_namespace_is_struct_value_keypath_accessible() {
        // The struct-based shape lets you write a KeyPath into Prisms.
        let kp: KeyPath<Pixel.Prisms, CoreFP.Prism<Pixel, Int>> = \.gray
        #expect(Pixel.prism[keyPath: kp].preview(.gray(7)) == 7)
    }

    @Test func generic_host_uses_static_var_prism() {
        // A generic enum uses a computed `static var prism` (since `static let` is forbidden
        // in generic contexts).
        #expect(Wrapped<String>.prism.some.preview(.some("hi")) == "hi")
        #expect(Wrapped<String>.prism.some.preview(.none) == nil)
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

// MARK: - Prismatic conformance & \.case key paths

private func requirePrismatic<T: Prismatic>(_ type: T.Type) {}

@Suite("@Prisms — Prismatic case key paths")
struct PrismsCaseKeyPathTests {
    @Test func autoConformsToPrismatic() {
        // Compiles only if `@Prisms` auto-conformed `Shape` to `Prismatic` (no hand-written extension).
        requirePrismatic(Shape.self)
    }

    @Test func caseKeyPathRecoversPrism() {
        let prism = Prism(\.circle as PrismKeyPath<Shape, Double>)
        #expect(prism.preview(.circle(3.14)) == 3.14)
        #expect(prism.preview(.empty) == nil)
        if case .circle(let value) = prism.review(2.0) {
            #expect(value == 2.0)
        } else {
            Issue.record("review should build .circle")
        }
    }
}
