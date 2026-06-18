// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
@testable import CoreFPOperators
import Testing

@Suite struct FunctionFunctorTests {
    // MARK: - Basic Functor Tests

    @Test func basicFmap() {
        let f: @Sendable (Int) -> Int = { $0 + 1 }
        let g: @Sendable (Int) -> String = { "\($0)" }

        let composed = fmap(g, f)

        #expect(composed(5) == "6")
        #expect(composed(10) == "11")
    }

    @Test func curriedFmap() {
        let f: @Sendable (Int) -> Int = { $0 * 2 }
        let toString: @Sendable (Int) -> String = { "\($0)" }

        // Use the curried version explicitly with type annotation
        let fmapToString: @Sendable (@escaping @Sendable (Int) -> Int) -> @Sendable (Int) -> String = fmap(toString)
        let composed = fmapToString(f)

        #expect(composed(5) == "10")
    }

    // MARK: - Functor Laws

    @Test func functorIdentityLaw() {
        // fmap id == id
        let f: @Sendable (Int) -> Int = { $0 * 2 }
        let identity: @Sendable (Int) -> Int = id

        let mapped = fmap(identity, f)

        // Both should produce the same results
        #expect(f(5) == mapped(5))
        #expect(f(10) == mapped(10))
    }

    @Test func functorCompositionLaw() {
        // fmap (g . f) == fmap g . fmap f
        let base: @Sendable (Int) -> Int = { $0 + 1 }
        let f: @Sendable (Int) -> Int = { $0 * 2 }
        let g: @Sendable (Int) -> String = { "\($0)" }

        // Left side: fmap (g . f)
        let left = fmap(compose(f, g), base)

        // Right side: (fmap g) . (fmap f)
        // fmap f applied to base gives us (Int) -> Int
        // then we need to apply fmap g to that
        let step1 = fmap(f, base)  // (Int) -> Int
        let right = fmap(g, step1)  // (Int) -> String

        #expect(left(5) == right(5))
        #expect(left(10) == right(10))
    }

    // MARK: - Functor Operators

    @Test func fmapOperator() {
        let f: @Sendable (Int) -> Int = { $0 + 1 }
        let g: @Sendable (Int) -> String = { "\($0)" }

        let composed = g <£> f

        #expect(composed(5) == "6")
        #expect(composed(10) == "11")
    }

    @Test func fmapOperatorComposition() {
        // Test multiple compositions using the operator
        let addOne: @Sendable (Int) -> Int = { $0 + 1 }
        let double: @Sendable (Int) -> Int = { $0 * 2 }
        let toString: @Sendable (Int) -> String = { "\($0)" }

        let composed = toString <£> double <£> addOne

        #expect(composed(5) == "12")  // (5 + 1) * 2 = 12
    }

    @Test func mapReplaceOperator() {
        let f: @Sendable (Int) -> String = { "\($0)" }

        let constant = f £> 99

        #expect(constant(1) == 99)
        #expect(constant(100) == 99)
    }

    @Test func mapReplaceFlippedOperator() {
        let f: @Sendable (Int) -> String = { "\($0)" }

        let constant = 42 <£ f

        #expect(constant(1) == 42)
        #expect(constant(100) == 42)
    }

    // MARK: - Practical Examples

    @Test func practicalExample() {
        // Compose string operations
        let trimWhitespace: @Sendable (String) -> String = { $0.trimmingCharacters(in: .whitespaces) }
        let uppercase: @Sendable (String) -> String = { $0.uppercased() }

        // We can use fmap to compose these
        let trimAndUpper = fmap(uppercase, trimWhitespace)

        #expect(trimAndUpper("  hello  ") == "HELLO")
        #expect(trimAndUpper("world") == "WORLD")
    }

    @Test func equivalenceWithComposition() {
        // fmap should be equivalent to function composition
        let f: @Sendable (Int) -> Int = { $0 + 1 }
        let g: @Sendable (Int) -> String = { "\($0)" }

        let viaFmap = fmap(g, f)
        let viaCompose = compose(f, g)

        #expect(viaFmap(5) == viaCompose(5))
        #expect(viaFmap(10) == viaCompose(10))
    }
}
