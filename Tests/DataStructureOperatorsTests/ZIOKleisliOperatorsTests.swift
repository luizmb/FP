import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

fileprivate enum E: Error, Equatable { case fail }
fileprivate typealias K<I, A> = ZIOKleisli<I, Int, A, E>

@Suite struct ZIOKleisliOperatorsTests {
    // MARK: - Functor operators

    @Test func fmapOperator() async {
        let k = K<Int, Int> { input in .pure(input) }
        let result = await ({ $0 * 3 } <£> k).run(4).provide(0).run()
        #expect(result == .success(12))
    }

    @Test func fmapFlippedOperator() async {
        let k = K<Int, Int> { input in .pure(input) }
        let result = await (k <&> { $0 + 10 }).run(5).provide(0).run()
        #expect(result == .success(15))
    }

    @Test func replaceRightOperator() async {
        let k = K<Int, Int> { input in .pure(input) }
        let result = await (k £> "replaced").run(99).provide(0).run()
        #expect(result == .success("replaced"))
    }

    @Test func replaceLeftOperator() async {
        let k = K<Int, Int> { input in .pure(input) }
        let result = await ("replaced" <£ k).run(99).provide(0).run()
        #expect(result == .success("replaced"))
    }

    // MARK: - Monad bind operators (Input fixed)

    @Test func bindOperator() async {
        let k = K<Int, Int> { input in .pure(input * 2) }
        let result = await (k >>- { K<Int, String>.pure("\($0)") }).run(5).provide(0).run()
        #expect(result == .success("10"))
    }

    @Test func bindFlippedOperator() async {
        let fn: @Sendable (Int) -> K<Int, String> = { K<Int, String>.pure("\($0)") }
        let k = K<Int, Int> { input in .pure(input + 1) }
        let result = await (fn -<< k).run(9).provide(0).run()
        #expect(result == .success("10"))
    }

    @Test func bindShortCircuitsOnFailure() async {
        let failing = K<Int, Int> { _ in ZIO { _ in .pure(.failure(.fail)) } }
        let result = await (failing >>- { K<Int, Int>.pure($0 + 1) }).run(0).provide(0).run()
        #expect(result == .failure(.fail))
    }

    // MARK: - Kleisli category composition operators (changes Input type)

    @Test func kleisliCompositionOperator() async {
        let k1 = K<Int, String> { n in .pure("\(n)") }
        let k2 = ZIOKleisli<String, Int, Int, E> { s in .pure(s.count) }
        let composed = k1 >=> k2
        let result = await composed.run(123).provide(0).run()
        #expect(result == .success(3))  // "\(123)".count == 3
    }

    @Test func kleisliCompositionBackOperator() async {
        let k1 = K<Int, String> { n in .pure("\(n)") }
        let k2 = ZIOKleisli<String, Int, Int, E> { s in .pure(s.count) }
        let composed = k2 <=< k1
        let result = await composed.run(123).provide(0).run()
        #expect(result == .success(3))
    }

    @Test func kleisliCompositionAndBackAreEquivalent() async {
        let k1 = K<Int, String> { n in .pure("\(n * 2)") }
        let k2 = ZIOKleisli<String, Int, Bool, E> { s in .pure(s.count > 2) }
        let a = await (k1 >=> k2).run(50).provide(0).run()
        let b = await (k2 <=< k1).run(50).provide(0).run()
        #expect(a == b)
    }

    @Test func kleisliCompositionChain() async {
        let k1 = K<Int, String>    { n in .pure("\(n)") }
        let k2 = ZIOKleisli<String, Int, Int, E>  { s in .pure(s.count) }
        let k3 = ZIOKleisli<Int, Int, Bool, E>    { n in .pure(n > 1) }
        let composed = k1 >=> k2 >=> k3
        let result = await composed.run(99).provide(0).run()
        #expect(result == .success(true))  // "\(99)".count == 2 > 1
    }

    @Test func kleisliCompositionShortCircuitsOnFailure() async {
        let failing = K<Int, Int> { _ in ZIO { _ in .pure(.failure(.fail)) } }
        let next = ZIOKleisli<Int, Int, String, E> { n in .pure("\(n)") }
        let result = await (failing >=> next).run(0).provide(0).run()
        #expect(result == .failure(.fail))
    }

    // MARK: - Distinguishing ZIOKleisli >=> from plain-function >=>

    @Test func kleisliOperatorResultIsZIOKleisli() async {
        // Verify the result of >=> is a ZIOKleisli (not just a function),
        // by applying further FAM operations to the composed value.
        let k1 = K<Int, Int> { n in .pure(n + 1) }
        let k2 = ZIOKleisli<Int, Int, Int, E> { n in .pure(n * 10) }
        let composed: ZIOKleisli<Int, Int, String, E> = (k1 >=> k2).map { "\($0)" }
        let result = await composed.run(4).provide(0).run()
        #expect(result == .success("50"))  // (4+1)*10 = 50
    }
}
