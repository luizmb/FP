import CoreFP
import DataStructure
import Testing

fileprivate enum E: Error, Equatable { case fail }
fileprivate typealias SUT<A> = ZIO<Int, A, E>

@Suite struct ZIOTests {
    // MARK: - Construction

    @Test func runsWithProvidedEnvironment() async {
        let zio = SUT<Int> { env in .pure(.success(env * 2)) }
        let result = await zio.provide(3).run()
        #expect(result == .success(6))
    }

    @Test func callAsFunctionMatchesProvide() async {
        let zio = SUT<Int> { env in .pure(.success(env + 1)) }
        let a = await zio.provide(5).run()
        let b = await zio(5).run()
        #expect(a == b)
    }

    // MARK: - Functor

    @Test func map() async {
        let result = await SUT<Int>.pure(4).map { $0 * 3 }.provide(0).run()
        #expect(result == .success(12))
    }

    @Test func mapShortCircuitsOnFailure() async {
        let zio = SUT<Int> { _ in .pure(.failure(.fail)) }
        let result = await zio.map { $0 * 10 }.provide(0).run()
        #expect(result == .failure(.fail))
    }

    @Test func fmapCurried() async {
        let lifted = SUT<Int>.fmap { $0 + 1 }
        let result = await lifted(.pure(9)).provide(0).run()
        #expect(result == .success(10))
    }

    @Test func replace() async {
        let result = await SUT<Int>.pure(42).replace("ok").provide(0).run()
        #expect(result == .success("ok"))
    }

    @Test func mapError() async {
        enum E2: Error, Equatable { case other }
        let zio = SUT<Int> { _ in .pure(.failure(.fail)) }
        let result = await zio.mapError { _ in E2.other }.provide(0).run()
        #expect(result == .failure(.other))
    }

    // MARK: - Applicative

    @Test func pure() async {
        let result = await SUT<String>.pure("hello").provide(0).run()
        #expect(result == .success("hello"))
    }

    @Test func seqRight() async {
        let result = await SUT<Int>.pure(1).seqRight(SUT<String>.pure("b")).provide(0).run()
        #expect(result == .success("b"))
    }

    @Test func seqLeft() async {
        let result = await SUT<Int>.pure(1).seqLeft(SUT<String>.pure("b")).provide(0).run()
        #expect(result == .success(1))
    }

    @Test func seqRightShortCircuitsOnLeftFailure() async {
        let left = SUT<Int> { _ in .pure(.failure(.fail)) }
        let result = await left.seqRight(SUT<String>.pure("b")).provide(0).run()
        #expect(result == .failure(.fail))
    }

    @Test func liftA2() async {
        let result = await liftA2ZIO({ $0 + $1 })(SUT<Int>.pure(3), SUT<Int>.pure(4)).provide(0).run()
        #expect(result == .success(7))
    }

    @Test func applyZIOFunction() async {
        let fn: SUT<@Sendable (Int) -> Int> = .pure({ $0 * 5 })
        let result = await applyZIO(fn, .pure(3)).provide(0).run()
        #expect(result == .success(15))
    }

    @Test func zipPair() async {
        let result = await ZIO<Int, (Int, String), E>.zip(.pure(1), .pure("a")).provide(0).run()
        guard case let .success(pair) = result else { Issue.record("Expected .success"); return }
        #expect(pair.0 == 1)
        #expect(pair.1 == "a")
    }

    @Test func zipShortCircuitsOnFirstFailure() async {
        let failing = SUT<Int> { _ in .pure(.failure(.fail)) }
        let result = await ZIO<Int, (Int, String), E>.zip(failing, .pure("a")).provide(0).run()
        guard case .failure(let e) = result else { Issue.record("Expected .failure"); return }
        #expect(e == .fail)
    }

    // MARK: - Monad

    @Test func flatMap() async {
        let result = await SUT<Int>.pure(2).flatMap { n in SUT<String>.pure("\(n * n)") }.provide(0).run()
        #expect(result == .success("4"))
    }

    @Test func flatMapShortCircuits() async {
        let zio = SUT<Int> { _ in .pure(.failure(.fail)) }
        let result = await zio.flatMap { SUT<Int>.pure($0 + 1) }.provide(0).run()
        #expect(result == .failure(.fail))
    }

    @Test func bind() async {
        let bound = SUT<Int>.bind { n in SUT<Int>.pure(n + 10) }
        let result = await bound(.pure(5)).provide(0).run()
        #expect(result == .success(15))
    }

    @Test func join() async {
        let outer = SUT<SUT<Int>>.pure(SUT<Int>.pure(42))
        let result = await SUT<SUT<Int>>.join(outer).provide(0).run()
        #expect(result == .success(42))
    }

    @Test func kleisli() async {
        let f: @Sendable (Int) -> SUT<Int>    = { n in SUT { env in .pure(.success(n + env)) } }
        let g: @Sendable (Int) -> SUT<String> = { n in SUT { _ in .pure(.success("\(n)")) } }
        let h = SUT<Int>.kleisli(f, g)
        let result = await h(10).provide(2).run()
        #expect(result == .success("12"))  // 10 + 2 = 12
    }

    @Test func kleisliBack() async {
        let f: @Sendable (Int) -> SUT<Int>    = { n in SUT { env in .pure(.success(n + env)) } }
        let g: @Sendable (Int) -> SUT<String> = { n in SUT { _ in .pure(.success("\(n)")) } }
        let h = SUT<Int>.kleisliBack(g, f)
        let result = await h(10).provide(2).run()
        #expect(result == .success("12"))
    }

    @Test func flatMapError() async {
        enum E2: Error, Equatable { case recovered }
        let failing = ZIO<Int, Int, E> { _ in .pure(.failure(.fail)) }
        let result = await failing.flatMapError { _ in ZIO<Int, Int, E2>.pure(99) }.provide(0).run()
        #expect(result == .success(99))
    }

    // MARK: - Reader operations

    @Test func ask() async {
        let result = await SUT<Int>.ask.provide(7).run()
        #expect(result == .success(7))
    }

    @Test func asks() async {
        let result = await SUT<Int>.asks { $0 * 3 }.provide(5).run()
        #expect(result == .success(15))
    }

    @Test func local() async {
        let result = await SUT<Int>.asks { $0 }.local { $0 + 100 }.provide(1).run()
        #expect(result == .success(101))
    }

    // MARK: - Void

    @Test func voidMethod() async {
        let result = await SUT<Int>.pure(42).void().provide(0).run()
        guard case .success = result else { Issue.record("Expected .success, got \(result)"); return }
    }
}
