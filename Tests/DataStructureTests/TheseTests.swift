// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct TheseCoreTests {
    // MARK: - Construction / Accessors / Match

    @Test func thisConstruction() {
        let these: These<String, Int> = .this("only a")
        #expect(these.isThis)
        #expect(!these.isThat)
        #expect(!these.isBoth)
        #expect(these.this == "only a")
        #expect(these.that == nil)
    }

    @Test func thatConstruction() {
        let these: These<String, Int> = .that(42)
        #expect(!these.isThis)
        #expect(these.isThat)
        #expect(!these.isBoth)
        #expect(these.this == nil)
        #expect(these.that == 42)
    }

    @Test func bothConstruction() {
        let these: These<String, Int> = .both("a", 42)
        #expect(!these.isThis)
        #expect(!these.isThat)
        #expect(these.isBoth)
        #expect(these.this == "a")
        #expect(these.that == 42)
    }

    @Test func matchThis() {
        let these: These<String, Int> = .this("a")
        let result = these.match(
            caseThis: { "this: \($0)" },
            caseThat: { "that: \($0)" },
            caseBoth: { a, b in "both: \(a), \(b)" }
        )
        #expect(result == "this: a")
    }

    @Test func matchThat() {
        let these: These<String, Int> = .that(42)
        let result = these.match(
            caseThis: { "this: \($0)" },
            caseThat: { "that: \($0)" },
            caseBoth: { a, b in "both: \(a), \(b)" }
        )
        #expect(result == "that: 42")
    }

    @Test func matchBoth() {
        let these: These<String, Int> = .both("a", 42)
        let result = these.match(
            caseThis: { "this: \($0)" },
            caseThat: { "that: \($0)" },
            caseBoth: { a, b in "both: \(a), \(b)" }
        )
        #expect(result == "both: a, 42")
    }

    @Test func equatable() {
        #expect(These<String, Int>.this("a") == .this("a"))
        #expect(These<String, Int>.that(1) == .that(1))
        #expect(These<String, Int>.both("a", 1) == .both("a", 1))
        #expect(These<String, Int>.this("a") != .that(1))
    }

    @Test func description() {
        #expect(These<String, Int>.this("a").description == ".this(a)")
        #expect(These<String, Int>.that(1).description == ".that(1)")
        #expect(These<String, Int>.both("a", 1).description == ".both(a, 1)")
    }

    // MARK: - Functor

    @Test func mapThis() {
        let this: These<String, Int> = .this("a")
        #expect(this.map { $0 * 2 } == .this("a"))
    }

    @Test func mapThat() {
        let that: These<String, Int> = .that(5)
        #expect(that.map { $0 * 2 } == .that(10))
    }

    @Test func mapBoth() {
        let both: These<String, Int> = .both("a", 5)
        #expect(both.map { $0 * 2 } == .both("a", 10))
    }

    @Test func fmapStatic() {
        let that: These<String, Int> = .that(5)
        #expect(These<String, Int>.fmap { $0 * 2 }(that) == .that(10))
    }

    @Test func mapThisFunctionThis() {
        let this: These<String, Int> = .this("a")
        #expect(this.mapThis { $0.uppercased() } == .this("A"))
    }

    @Test func mapThisFunctionThat() {
        let that: These<String, Int> = .that(5)
        #expect(that.mapThis { $0.uppercased() } == .that(5))
    }

    @Test func mapThisFunctionBoth() {
        let both: These<String, Int> = .both("a", 5)
        #expect(both.mapThis { $0.uppercased() } == .both("A", 5))
    }

    @Test func mapThisCurried() {
        let transform = These<String, Int>.mapThis { $0.uppercased() }
        #expect(transform(.both("a", 5)) == .both("A", 5))
    }

    @Test func bimapAllCases() {
        let this: These<String, Int> = .this("a")
        let that: These<String, Int> = .that(5)
        let both: These<String, Int> = .both("a", 5)

        #expect(this.bimap({ $0.uppercased() }, { $0 * 2 }) == .this("A"))
        #expect(that.bimap({ $0.uppercased() }, { $0 * 2 }) == .that(10))
        #expect(both.bimap({ $0.uppercased() }, { $0 * 2 }) == .both("A", 10))
    }

    @Test func bimapCurried() {
        let transform = These<String, Int>.bimap({ $0.uppercased() }, { $0 * 2 })
        #expect(transform(.both("a", 5)) == .both("A", 10))
    }

    @Test func functorIdentityLaw() {
        let this: These<String, Int> = .this("a")
        let that: These<String, Int> = .that(5)
        let both: These<String, Int> = .both("a", 5)

        #expect(this.map(id) == this)
        #expect(that.map(id) == that)
        #expect(both.map(id) == both)
    }

    @Test func functorCompositionLaw() {
        let both: These<String, Int> = .both("a", 5)
        let f: @Sendable (Int) -> Int = { $0 * 2 }
        let g: @Sendable (Int) -> String = { "\($0)" }

        #expect(both.map(compose(f, g)) == both.map(f).map(g))
    }

    // MARK: - Applicative: pure

    @Test func pure() {
        let these = These<String, Int>.pure(42)
        #expect(these == .that(42))
    }

    // MARK: - Applicative: apply — all 7 cases of the Haskell semantics table

    @Test func applyThisFnIgnoresThisArg() {
        // This a <*> This b = This a
        let fn: These<String, @Sendable (Int) -> Int> = .this("fn error")
        let arg: These<String, Int> = .this("arg error")
        #expect(These<String, Int>.apply(fn, arg) == .this("fn error"))
    }

    @Test func applyThisFnIgnoresThatArg() {
        // This a <*> That x = This a
        let fn: These<String, @Sendable (Int) -> Int> = .this("fn error")
        let arg: These<String, Int> = .that(5)
        #expect(These<String, Int>.apply(fn, arg) == .this("fn error"))
    }

    @Test func applyThisFnIgnoresBothArg() {
        // This a <*> These b x = This a
        let fn: These<String, @Sendable (Int) -> Int> = .this("fn error")
        let arg: These<String, Int> = .both("arg error", 5)
        #expect(These<String, Int>.apply(fn, arg) == .this("fn error"))
    }

    @Test func applyThatFnWithThisArg() {
        // That f <*> This b = This b
        let fn: These<String, @Sendable (Int) -> Int> = .that { $0 * 2 }
        let arg: These<String, Int> = .this("arg error")
        #expect(These<String, Int>.apply(fn, arg) == .this("arg error"))
    }

    @Test func applyThatFnWithThatArg() {
        // That f <*> That x = That (f x)
        let fn: These<String, @Sendable (Int) -> Int> = .that { $0 * 2 }
        let arg: These<String, Int> = .that(5)
        #expect(These<String, Int>.apply(fn, arg) == .that(10))
    }

    @Test func applyThatFnWithBothArg() {
        // That f <*> These b x = These b (f x)
        let fn: These<String, @Sendable (Int) -> Int> = .that { $0 * 2 }
        let arg: These<String, Int> = .both("b", 5)
        #expect(These<String, Int>.apply(fn, arg) == .both("b", 10))
    }

    @Test func applyBothFnWithThisArg() {
        // These a _ <*> This b = This (a <> b)
        let fn: These<String, @Sendable (Int) -> Int> = .both("a") { $0 * 2 }
        let arg: These<String, Int> = .this("b")
        #expect(These<String, Int>.apply(fn, arg) == .this("ab"))
    }

    @Test func applyBothFnWithThatArg() {
        // These a f <*> That x = These a (f x)
        let fn: These<String, @Sendable (Int) -> Int> = .both("a") { $0 * 2 }
        let arg: These<String, Int> = .that(5)
        #expect(These<String, Int>.apply(fn, arg) == .both("a", 10))
    }

    @Test func applyBothFnWithBothArg() {
        // These a f <*> These b x = These (a <> b) (f x)
        let fn: These<String, @Sendable (Int) -> Int> = .both("a") { $0 * 2 }
        let arg: These<String, Int> = .both("b", 5)
        #expect(These<String, Int>.apply(fn, arg) == .both("ab", 10))
    }

    // MARK: - Applicative: liftA2 / seqRight / seqLeft

    @Test func liftA2Both() {
        let add: @Sendable (Int, Int) -> Int = { $0 + $1 }
        let lifted = These<String, Int>.liftA2(add)

        let both1: These<String, Int> = .both("a", 5)
        let both2: These<String, Int> = .both("b", 10)
        #expect(lifted(both1, both2) == .both("ab", 15))
    }

    @Test func liftA2ThisShortCircuits() {
        let add: @Sendable (Int, Int) -> Int = { $0 + $1 }
        let lifted = These<String, Int>.liftA2(add)

        let this: These<String, Int> = .this("error")
        let that: These<String, Int> = .that(10)
        #expect(lifted(this, that) == .this("error"))
    }

    @Test func seqRightAccumulates() {
        let both1: These<String, Int> = .both("a", 5)
        let both2: These<String, Int> = .both("b", 10)
        #expect(both1.seqRight(both2) == .both("ab", 10))
    }

    @Test func seqLeftAccumulates() {
        let both1: These<String, Int> = .both("a", 5)
        let both2: These<String, Int> = .both("b", 10)
        #expect(both1.seqLeft(both2) == .both("ab", 5))
    }

    // MARK: - Monad: flatMap for all 3 cases

    @Test func flatMapThisShortCircuits() {
        // This a >>= _ = This a
        let this: These<String, Int> = .this("error")
        let result = this.flatMap { (n: Int) in These<String, Int>.that(n * 2) }
        #expect(result == .this("error"))
    }

    @Test func flatMapThatAppliesContinuation() {
        // That x >>= k = k x
        let that: These<String, Int> = .that(5)
        let result = that.flatMap { n in These<String, Int>.that(n * 2) }
        #expect(result == .that(10))
    }

    @Test func flatMapBothContinuationReturnsThis() {
        // These a x >>= k, k x = This b  ->  This (a <> b)
        let both: These<String, Int> = .both("a", 5)
        let result = both.flatMap(const(These<String, Int>.this("b")))
        #expect(result == .this("ab"))
    }

    @Test func flatMapBothContinuationReturnsThat() {
        // These a x >>= k, k x = That y  ->  These a y
        let both: These<String, Int> = .both("a", 5)
        let result = both.flatMap { n in These<String, Int>.that(n * 2) }
        #expect(result == .both("a", 10))
    }

    @Test func flatMapBothContinuationReturnsBoth() {
        // These a x >>= k, k x = These b y  ->  These (a <> b) y
        let both: These<String, Int> = .both("a", 5)
        let result = both.flatMap { n in These<String, Int>.both("b", n * 2) }
        #expect(result == .both("ab", 10))
    }

    @Test func bind() {
        let transform: @Sendable (Int) -> These<String, Int> = { .that($0 * 2) }
        let that: These<String, Int> = .that(5)
        #expect(These.bind(transform)(that) == .that(10))
    }

    @Test func join() {
        let nested: These<String, These<String, Int>> = .that(.that(5))
        #expect(These.join(nested) == .that(5))

        let nestedThis: These<String, These<String, Int>> = .this("outer")
        #expect(These.join(nestedThis) == .this("outer"))

        let nestedInnerThis: These<String, These<String, Int>> = .that(.this("inner"))
        #expect(These.join(nestedInnerThis) == .this("inner"))
    }

    @Test func kleisliComposition() {
        let f: @Sendable (Int) -> These<String, Int> = { .that($0 * 2) }
        let g: @Sendable (Int) -> These<String, String> = { .that("\($0)") }

        let composed = These<String, Int>.kleisli(f, g)
        #expect(composed(5) == .that("10"))
    }

    @Test func kleisliBack() {
        let f: @Sendable (Int) -> These<String, Int> = { .that($0 * 2) }
        let g: @Sendable (Int) -> These<String, String> = { .that("\($0)") }

        let composed = These<String, Int>.kleisliBack(g, f)
        #expect(composed(5) == .that("10"))
    }

    // MARK: - Monad laws (using String as the Semigroup A)

    @Test func monadLeftIdentityLaw() {
        // return a >>= f == f a
        let a = 5
        let f: @Sendable (Int) -> These<String, Int> = { .that($0 * 2) }

        let lhs = These<String, Int>.that(a).flatMap(f)
        let rhs = f(a)
        #expect(lhs == rhs)
    }

    @Test func monadRightIdentityLaw() {
        // m >>= return == m
        let both: These<String, Int> = .both("a", 5)
        let result = both.flatMap { These<String, Int>.that($0) }
        #expect(result == both)
    }

    @Test func monadAssociativityLaw() {
        // (m >>= f) >>= g == m >>= (\x -> f x >>= g)
        let m: These<String, Int> = .both("a", 5)
        let f: @Sendable (Int) -> These<String, Int> = { .both("b", $0 * 2) }
        let g: @Sendable (Int) -> These<String, Int> = { .both("c", $0 + 10) }

        let lhs = m.flatMap(f).flatMap(g)
        let rhs = m.flatMap { x in f(x).flatMap(g) }
        #expect(lhs == rhs)
    }

    @Test func semigroupAccumulationWithArrayOfString() {
        let both1: These<[String], Int> = .both(["a"], 5)
        let both2: These<[String], Int> = .both(["b"], 10)
        let lifted = These<[String], Int>.liftA2 { $0 + $1 }
        #expect(lifted(both1, both2) == .both(["a", "b"], 15))
    }

    // MARK: - Interop: fromEither

    @Test func fromEitherLeft() {
        let either: Either<String, Int> = .left("error")
        #expect(These.fromEither(either) == .this("error"))
    }

    @Test func fromEitherRight() {
        let either: Either<String, Int> = .right(42)
        #expect(These.fromEither(either) == .that(42))
    }

    // MARK: - Interop: align

    @Test func alignBoth() {
        let result = These<String, Int>.align("a", 1)
        #expect(result == .both("a", 1))
    }

    @Test func alignOnlyThis() {
        let result = These<String, Int>.align("a", nil)
        #expect(result == .this("a"))
    }

    @Test func alignOnlyThat() {
        let result = These<String, Int>.align(nil, 1)
        #expect(result == .that(1))
    }

    @Test func alignNeither() {
        let result = These<String, Int>.align(nil, nil)
        #expect(result == nil)
    }
}
