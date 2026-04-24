import CoreFP
import DataStructure
import Testing

private enum E: Error, Equatable { case fail }
private typealias K<I, A> = ZIOKleisli<I, Int, A, E>

@Suite struct ZIOKleisliTests {
    // MARK: - Construction

    @Test func runsWithInput() async {
        let k = K<Int, Int> { input in ZIO { env in .pure(.success(input + env)) } }
        let result = await k.run(3).provide(10).run()
        #expect(result == .success(13))
    }

    @Test func callAsFunctionMatchesRun() async {
        let k = K<Int, String> { input in .pure("\(input)") }
        let a = await k.run(5).provide(0).run()
        let b = await k(5).provide(0).run()
        #expect(a == b)
    }

    @Test func lift() async {
        let zio = ZIO<Int, String, E>.pure("lifted")
        let k: K<Bool, String> = .lift(zio)
        let result = await k.run(false).provide(0).run()
        #expect(result == .success("lifted"))
    }

    // MARK: - Functor

    @Test func map() async {
        let k = K<Int, Int> { input in .pure(input * 2) }
        let result = await k.map { $0 + 1 }.run(5).provide(0).run()
        #expect(result == .success(11))
    }

    @Test func mapShortCircuitsOnFailure() async {
        let k = K<Int, Int> { _ in ZIO { _ in .pure(.failure(.fail)) } }
        let result = await k.map { $0 * 10 }.run(1).provide(0).run()
        #expect(result == .failure(.fail))
    }

    @Test func fmapCurried() async {
        let lifted = K<Int, Int>.fmap { $0 * 3 }
        let k = K<Int, Int> { input in .pure(input) }
        let result = await lifted(k).run(4).provide(0).run()
        #expect(result == .success(12))
    }

    @Test func replace() async {
        let k = K<Int, Int> { input in .pure(input) }
        let result = await k.replace("ok").run(99).provide(0).run()
        #expect(result == .success("ok"))
    }

    @Test func mapError() async {
        enum E2: Error, Equatable { case other }
        let k = K<Int, Int> { _ in ZIO { _ in .pure(.failure(.fail)) } }
        let result = await k.mapError { _ in E2.other }.run(0).provide(0).run()
        #expect(result == .failure(.other))
    }

    @Test func contramap() async {
        // ZIOKleisli expects Int input, we provide String, transform via contramap
        let k = ZIOKleisli<String, Int, Int, E> { input in .pure(input.count) }
        let transformed = k.contramap { (input: Int) in String(repeating: "a", count: input) }
        let result = await transformed.run(3).provide(0).run()  // "aaa" has length 3
        #expect(result == .success(3))
    }

    @Test func contramapCurried() async {
        let k = ZIOKleisli<String, Int, Int, E> { input in .pure(input.count) }
        let lifted = ZIOKleisli<String, Int, Int, E>.contramap { (input: Int) in String(repeating: "b", count: input) }
        let result = await lifted(k).run(4).provide(0).run()  // "bbbb" has length 4
        #expect(result == .success(4))
    }

    @Test func contramapEnvironment() async {
        // ZIOKleisli expects Int env, we provide String env
        let k = ZIOKleisli<Int, Int, Int, E> { input in ZIO { env in .pure(.success(input + env)) } }
        let transformed: ZIOKleisli<Int, String, Int, E> = k.contramapEnvironment { (env: String) -> Int in env.count }
        let result = await transformed.run(5).provide("xx").run()  // input 5 + env "xx" (count 2) = 7
        #expect(result == .success(7))
    }

    @Test func contramapEnvironmentCurried() async {
        let k = ZIOKleisli<Int, Int, Int, E> { input in ZIO { env in .pure(.success(input + env)) } }
        let lifted: (ZIOKleisli<Int, Int, Int, E>) -> ZIOKleisli<Int, String, Int, E> = ZIOKleisli<Int, Int, Int, E>.contramapEnvironment { (env: String) -> Int in env.count }
        let result = await lifted(k).run(3).provide("yyy").run()  // 3 + 3 = 6
        #expect(result == .success(6))
    }

    @Test func dimap() async {
        // Transform input (Int -> String), env (String -> Int), and output (Int -> String)
        let k = ZIOKleisli<String, Int, Int, E> { input in ZIO { env in .pure(.success(input.count + env)) } }
        let transformed: ZIOKleisli<Int, String, String, E> = k.dimap(
            { (input: Int) -> String in String(repeating: "i", count: input) },  // contramap input
            { (env: String) -> Int in env.count },                                // contramap env
            { (n: Int) -> String in "result:\(n)" }                               // map output
        )
        let result = await transformed.run(2).provide("env").run()  // "ii" (2) + "env" (3) = 5 -> "result:5"
        #expect(result == .success("result:5"))
    }

    @Test func dimapCurried() async {
        let k = ZIOKleisli<String, Int, Int, E> { input in ZIO { env in .pure(.success(input.count + env)) } }
        let lifted: (ZIOKleisli<String, Int, Int, E>) -> ZIOKleisli<Int, String, Int, E> = ZIOKleisli<String, Int, Int, E>.dimap(
            { (input: Int) -> String in String(repeating: "x", count: input) },
            { (env: String) -> Int in env.count },
            { (n: Int) -> Int in n * 2 }
        )
        let result = await lifted(k).run(1).provide("ab").run()  // "x" (1) + "ab" (2) = 3 * 2 = 6
        #expect(result == .success(6))
    }

    // MARK: - Monad (Input fixed)

    @Test func pure() async {
        let k = K<String, Int>.pure(42)
        let result = await k.run("ignored").provide(0).run()
        #expect(result == .success(42))
    }

    @Test func flatMap() async {
        let k = K<Int, Int> { input in .pure(input * 2) }
        let result = await k.flatMap { n in K<Int, String>.pure("\(n)") }.run(5).provide(0).run()
        #expect(result == .success("10"))
    }

    @Test func flatMapShortCircuits() async {
        let k = K<Int, Int> { _ in ZIO { _ in .pure(.failure(.fail)) } }
        let result = await k.flatMap { K<Int, Int>.pure($0 + 1) }.run(0).provide(0).run()
        #expect(result == .failure(.fail))
    }

    @Test func flatMapThreadsSameInput() async {
        let k = K<Int, Int> { input in ZIO { env in .pure(.success(input + env)) } }
        // flatMap receives success and creates another arrow that also reads the same input
        let chained = k.flatMap { n in
            K<Int, String> { input in ZIO { _ in .pure(.success("\(n)-\(input)")) } }
        }
        let result = await chained.run(3).provide(10).run()
        #expect(result == .success("13-3"))  // n=13 (3+10), input=3 threaded through
    }

    @Test func bind() async {
        let bound = K<Int, Int>.bind { n in K<Int, Int>.pure(n + 100) }
        let result = await bound(K<Int, Int>.pure(5)).run(0).provide(0).run()
        #expect(result == .success(105))
    }

    @Test func join() async {
        let inner = K<Int, Int>.pure(7)
        let outer = K<Int, K<Int, Int>>.pure(inner)
        let result = await K<Int, K<Int, Int>>.join(outer).run(0).provide(0).run()
        #expect(result == .success(7))
    }

    // MARK: - Kleisli category composition (changes Input type)

    @Test func andThen() async {
        let k1 = K<Int, String> { input in .pure("\(input)") }
        let k2 = ZIOKleisli<String, Int, Int, E> { s in .pure(s.count) }
        let composed = k1.andThen(k2)
        let result = await composed.run(1_234).provide(0).run()
        #expect(result == .success(4))  // "\(1234)".count == 4
    }

    @Test func compose() async {
        let k1 = K<Int, String> { input in .pure("\(input)") }
        let k2 = ZIOKleisli<String, Int, Int, E> { s in .pure(s.count) }
        let composed = k2.compose(k1)
        let result = await composed.run(1_234).provide(0).run()
        #expect(result == .success(4))
    }

    @Test func andThenAndComposeAreInverse() async {
        let k1 = K<Int, String> { input in .pure("\(input)") }
        let k2 = ZIOKleisli<String, Int, Int, E> { s in .pure(s.count) }
        let a = await k1.andThen(k2).run(999).provide(0).run()
        let b = await k2.compose(k1).run(999).provide(0).run()
        #expect(a == b)
    }

    @Test func kleisliStaticComposition() async {
        let k1 = K<Int, String> { input in .pure("\(input * 2)") }
        let k2 = ZIOKleisli<String, Int, Int, E> { s in .pure(s.count) }
        // Self.Success is the middle type (output of f = input of g), so use String here.
        let composed = ZIOKleisli<Int, Int, String, E>.kleisli(k1, k2)
        let result = await composed.run(50).provide(0).run()
        #expect(result == .success(3))  // "\(100)".count == 3
    }

    @Test func andThenShortCircuitsOnFailure() async {
        let failing = K<Int, Int> { _ in ZIO { _ in .pure(.failure(.fail)) } }
        let next = ZIOKleisli<Int, Int, String, E> { n in .pure("\(n)") }
        let result = await failing.andThen(next).run(0).provide(0).run()
        #expect(result == .failure(.fail))
    }
}
