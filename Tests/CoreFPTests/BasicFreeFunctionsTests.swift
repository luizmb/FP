@testable import CoreFP
import Testing

@Suite struct BasicFreeFunctionsTests {
    // MARK: - ignore

    @Test func ignoreZeroArgs() {
        ignore()
    }

    @Test func ignoreOneArg() {
        ignore(42)
        ignore("hello")
    }

    @Test func ignoreTwoArgs() {
        ignore(1, "hello")
        ignore(true, 3.14)
    }

    @Test func ignoreThreeArgs() {
        ignore(1, "hello", true)
        ignore(0.0, 0, "x")
    }

    @Test func ignoreFourArgs() {
        // Uses the 4-fixed + variadic overload with 0 trailing variadic elements
        ignore(1, 2, 3, 4)
    }

    @Test func ignoreFiveOrMoreArgs() {
        // Uses the 4-fixed + variadic overload with trailing variadic elements
        ignore(1, 2, 3, 4, 5)
        ignore(1, 2, 3, 4, 5, 6, 7)
    }

    @Test func ignoreReturnIsVoid() {
        let result: Void = ignore(42)
        _ = result
    }

    // MARK: - const

    @Test func constZeroIgnoredArgs() {
        let f: () -> Int = const(42)
        #expect(f() == 42)
    }

    @Test func constOneIgnoredArg() {
        let f: (String) -> Int = const(42)
        #expect(f("ignored") == 42)
        #expect(f("anything") == 42)
    }

    @Test func constTwoIgnoredArgs() {
        let f: (String, Bool) -> Int = const(42)
        #expect(f("ignored", true) == 42)
        #expect(f("anything", false) == 42)
    }

    @Test func constThreeIgnoredArgs() {
        let f: (String, Bool, Double) -> Int = const(42)
        #expect(f("ignored", true, 3.14) == 42)
    }

    @Test func constFourIgnoredArgs() {
        // Uses the 4-fixed + variadic overload with 0 trailing variadic elements
        let f: (String, Bool, Double, Int) -> Int = const(42)
        #expect(f("ignored", true, 3.14, 0) == 42)
    }

    @Test func constFiveOrMoreIgnoredArgs() {
        // Uses the 4-fixed + variadic overload with trailing variadic elements
        let f: (Int, Int, Int, Int, Int) -> String = const("done")
        #expect(f(1, 2, 3, 4, 5) == "done")
    }

    @Test func constReturnsFixedValue() {
        let sentinel = "sentinel"
        let f: (Int) -> String = const(sentinel)
        #expect(f(0) == sentinel)
        #expect(f(99) == sentinel)
        #expect(f(-1) == sentinel)
    }

    // MARK: - fail

    // `fail` returns a closure that calls fatalError — it cannot be invoked safely in tests.
    // These tests verify that each arity overload resolves to the expected function type.

    @Test func failZeroArgType() {
        let _: () -> String = fail("not implemented")
    }

    @Test func failOneArgType() {
        let _: (Int) -> String = fail("not implemented")
    }

    @Test func failTwoArgType() {
        let _: (Int, String) -> Bool = fail("not implemented")
    }

    @Test func failThreeArgType() {
        let _: (Int, String, Bool) -> Double = fail("not implemented")
    }

    @Test func failFourArgType() {
        // 4-fixed + variadic overload with 0 trailing variadic elements
        let _: (Int, String, Bool, Double) -> Float = fail("not implemented")
    }

    @Test func failFiveArgType() {
        // 4-fixed + variadic overload with 1 trailing variadic element
        let _: (Int, String, Bool, Double, Float) -> Character = fail("not implemented")
    }
}
