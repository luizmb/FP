import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

private enum E: Error, Equatable { case fail }
private typealias SUT<A> = ZIO<Int, A, E>

@Suite struct ZIOOperatorsTests {
    // MARK: - Functor operators

    @Test func fmapOperator() async {
        let result = await ({ $0 * 2 } <£> SUT<Int>.pure(5)).provide(0).run()
        #expect(result == .success(10))
    }

    @Test func fmapFlippedOperator() async {
        let result = await (SUT<Int>.pure(5) <&> { $0 * 2 }).provide(0).run()
        #expect(result == .success(10))
    }

    @Test func replaceRightOperator() async {
        let result = await (SUT<Int>.pure(5) £> "x").provide(0).run()
        #expect(result == .success("x"))
    }

    @Test func replaceLeftOperator() async {
        let result = await ("x" <£ SUT<Int>.pure(5)).provide(0).run()
        #expect(result == .success("x"))
    }

    @Test func contramapEnvironmentOperator() async {
        // (r2 -> r) >>> ZIO<r, a, e> = ZIO<r2, a, e>
        let zio = ZIO<String, Int, E> { env in .pure(.success(env.count)) }
        let transformEnv: @Sendable (Int) -> String = { String(repeating: "x", count: $0) }
        let result = await (transformEnv >>> zio).provide(3).run()  // "xxx" has length 3
        #expect(result == .success(3))
    }

    // MARK: - Applicative operators

    @Test func applyOperator() async {
        let fn: SUT<@Sendable (Int) -> Int> = .pure({ $0 + 3 })
        let result = await (fn <*> .pure(7)).provide(0).run()
        #expect(result == .success(10))
    }

    @Test func seqRightOperator() async {
        let result = await (SUT<Int>.pure(1) *> SUT<String>.pure("b")).provide(0).run()
        #expect(result == .success("b"))
    }

    @Test func seqLeftOperator() async {
        let result = await (SUT<Int>.pure(1) <* SUT<String>.pure("b")).provide(0).run()
        #expect(result == .success(1))
    }

    // MARK: - Monad operators

    @Test func bindOperator() async {
        let result = await (SUT<Int>.pure(4) >>- { .pure($0 * $0) }).provide(0).run()
        #expect(result == .success(16))
    }

    @Test func bindFlippedOperator() async {
        let fn: @Sendable (Int) -> SUT<Int> = { .pure($0 + 1) }
        let result = await (fn -<< .pure(9)).provide(0).run()
        #expect(result == .success(10))
    }

    @Test func kleisliOperator() async {
        let f: @Sendable (Int) -> SUT<Int> = { .pure($0 + 1) }
        let g: @Sendable (Int) -> SUT<Int> = { .pure($0 * 2) }
        let h = f >=> g
        let result = await h(3).provide(0).run()
        #expect(result == .success(8))  // (3 + 1) * 2 = 8
    }

    @Test func kleisliBackOperator() async {
        let f: @Sendable (Int) -> SUT<Int> = { .pure($0 + 1) }
        let g: @Sendable (Int) -> SUT<Int> = { .pure($0 * 2) }
        let h = g <=< f
        let result = await h(3).provide(0).run()
        #expect(result == .success(8))
    }

    @Test func kleisliAndKleisliBackAreEquivalent() async {
        let f: @Sendable (Int) -> SUT<Int>    = { .pure($0 + 10) }
        let g: @Sendable (Int) -> SUT<String> = { .pure("\($0)") }
        let a = await (f >=> g)(1).provide(0).run()
        let b = await (g <=< f)(1).provide(0).run()
        #expect(a == b)
    }

    // MARK: - Short-circuit propagation

    @Test func failureShortCircuitsThroughBindOperator() async {
        let failing = SUT<Int> { _ in .pure(.failure(.fail)) }
        let result = await (failing >>- { .pure($0 + 1) }).provide(0).run()
        #expect(result == .failure(.fail))
    }

    @Test func failureShortCircuitsThroughKleisliOperator() async {
        let f: @Sendable (Int) -> SUT<Int> = { _ in ZIO { _ in .pure(.failure(.fail)) } }
        let g: @Sendable (Int) -> SUT<Int> = { .pure($0 * 2) }
        let result = await (f >=> g)(0).provide(0).run()
        #expect(result == .failure(.fail))
    }
}
