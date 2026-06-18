// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

// Hand-rolled `Prismatic` conformances (the shape `@Prisms` generates), so these tests exercise
// the `PrismFocus` / `\.case` mechanism independently of the macro.

private enum Sign: Equatable, Sendable {
    case positive(Int)
    case negative(String)
}

extension Sign: Prismatic {
    struct Prisms: Sendable {
        let positive = Prism<Sign, Int>(
            preview: { if case let .positive(value) = $0 { value } else { nil } },
            review: Sign.positive
        )
        let negative = Prism<Sign, String>(
            preview: { if case let .negative(value) = $0 { value } else { nil } },
            review: Sign.negative
        )
    }

    static let prism = Prisms()
}

private enum Outer: Equatable, Sendable {
    case sign(Sign)
    case flag(Bool)
}

extension Outer: Prismatic {
    struct Prisms: Sendable {
        let sign = Prism<Outer, Sign>(
            preview: { if case let .sign(value) = $0 { value } else { nil } },
            review: Outer.sign
        )
        let flag = Prism<Outer, Bool>(
            preview: { if case let .flag(value) = $0 { value } else { nil } },
            review: Outer.flag
        )
    }

    static let prism = Prisms()
}

@Suite(#"PrismFocus / \.case key paths"#)
struct PrismFocusTests {
    @Test func caseKeyPathRecoversPrismPreview() {
        let prism = Prism(\.positive as PrismKeyPath<Sign, Int>)
        #expect(prism.preview(.positive(5)) == 5)
        #expect(prism.preview(.negative("x")) == nil)
    }

    @Test func caseKeyPathRecoversPrismReview() {
        let prism = Prism(\.negative as PrismKeyPath<Sign, String>)
        #expect(prism.review("hi") == .negative("hi"))
    }

    @Test func nestedCaseKeyPathComposes() {
        // `\.sign.positive` drills Outer → Sign → Int via native key-path appending.
        let prism = Prism(\.sign.positive as PrismKeyPath<Outer, Int>)
        #expect(prism.preview(.sign(.positive(3))) == 3)
        #expect(prism.preview(.sign(.negative("n"))) == nil)
        #expect(prism.preview(.flag(true)) == nil)
        #expect(prism.review(9) == .sign(.positive(9)))
    }

    @Test func recoveredPrismEqualsNamespaceForm() {
        // \.case must agree with the direct namespace access (Sign.prism.positive).
        let viaKeyPath = Prism(\.positive as PrismKeyPath<Sign, Int>)
        let viaNamespace = Sign.prism.positive
        #expect(viaKeyPath.preview(.positive(7)) == viaNamespace.preview(.positive(7)))
        #expect(viaKeyPath.review(7) == viaNamespace.review(7))
    }
}
