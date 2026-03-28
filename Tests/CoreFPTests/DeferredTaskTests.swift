import Testing
import CoreFP

private enum TestError: Error, Equatable { case err }

@Suite struct DeferredTaskTests {

    // MARK: - Lazy behavior

    @Test func doesNotRunUntilCalled() async {
        nonisolated(unsafe) var ran = false
        let task = DeferredTask<Int> { ran = true; return 42 }
        #expect(!ran, "body must not run before .run()")
        let result = await task.run()
        #expect(ran)
        #expect(result == 42)
    }

    // MARK: - Functor

    @Test func fmap() async {
        let task = DeferredTask<Int> { 5 }
        let result = await task.fmap { $0 * 2 }.run()
        #expect(result == 10)
    }

    @Test func replace() async {
        let task = DeferredTask<Int> { 5 }
        let result = await task.replace("done").run()
        #expect(result == "done")
    }

    // MARK: - Applicative

    @Test func pure() async {
        let result = await DeferredTask<Int>.pure(7).run()
        #expect(result == 7)
    }

    @Test func applySequential() async {
        let fns = DeferredTask<@Sendable (Int) -> Int> { { $0 * 3 } }
        let vals = DeferredTask<Int> { 4 }
        let result = await applyDeferredTask(fns, vals).run()
        #expect(result == 12)
    }

    @Test func seqRight() async {
        let lhs = DeferredTask<Int> { 1 }
        let rhs = DeferredTask<String> { "hello" }
        let result = await lhs.seqRight(rhs).run()
        #expect(result == "hello")
    }

    @Test func seqLeft() async {
        let lhs = DeferredTask<Int> { 99 }
        let rhs = DeferredTask<String> { "ignored" }
        let result = await lhs.seqLeft(rhs).run()
        #expect(result == 99)
    }

    // MARK: - Monad

    @Test func flatMap() async {
        let task = DeferredTask<Int> { 5 }
        let result = await task.flatMap { n in DeferredTask<String> { "n=\(n)" } }.run()
        #expect(result == "n=5")
    }

    @Test func kleisli() async {
        let f: @Sendable (Int) -> DeferredTask<Int> = { n in DeferredTask { n + 1 } }
        let g: @Sendable (Int) -> DeferredTask<String> = { n in DeferredTask { "v\(n)" } }
        let fg = DeferredTask<Int>.kleisli(f, g)
        let result = await fg(4).run()
        #expect(result == "v5")
    }

    // MARK: - Zip

    @Test func zipCollectsBothResults() async {
        let ta = DeferredTask<Int> { 1 }
        let tb = DeferredTask<String> { "a" }
        let result = await DeferredTask.zip(ta, tb).run()
        #expect(result.0 == 1)
        #expect(result.1 == "a")
    }

    @Test func zipRunsFirstThenSecond() async {
        nonisolated(unsafe) var order: [Int] = []
        let ta = DeferredTask<Int> { order.append(1); return 1 }
        let tb = DeferredTask<Int> { order.append(2); return 2 }
        _ = await DeferredTask.zip(ta, tb).run()
        #expect(order == [1, 2])
    }

    @Test func zipVariadicThreeArgs() async {
        let ta = DeferredTask<Int> { 1 }
        let tb = DeferredTask<String> { "b" }
        let tc = DeferredTask<Bool> { true }
        let result = await DeferredTask.zip(ta, tb, tc).run()
        #expect(result.0 == 1)
        #expect(result.1 == "b")
        #expect(result.2 == true)
    }

    @Test func zipVariadicFourArgs() async {
        let ta = DeferredTask<Int> { 1 }
        let tb = DeferredTask<String> { "b" }
        let tc = DeferredTask<Bool> { true }
        let td = DeferredTask<Double> { 3.14 }
        let result = await DeferredTask.zip(ta, tb, tc, td).run()
        #expect(result.0 == 1)
        #expect(result.1 == "b")
        #expect(result.2 == true)
        #expect(result.3 == 3.14)
    }

    @Test func zipIsLazy() async {
        nonisolated(unsafe) var ran = false
        let ta = DeferredTask<Int> { 1 }
        let tb = DeferredTask<String> { ran = true; return "x" }
        let zipped = DeferredTask.zip(ta, tb)
        #expect(!ran, "zip must not run tasks before .run()")
        _ = await zipped.run()
        #expect(ran)
    }

    // MARK: - TOptional

    @Test func tOptionalMapT() async {
        let task = DeferredTask<Int?> { 3 }
        let result = await mapTDeferredTaskOptional({ $0 * 2 }, task).run()
        #expect(result == 6)
    }

    @Test func tOptionalFlatMapTSome() async {
        let task = DeferredTask<Int?> { 5 }
        let result = await flatMapTDeferredTaskOptional(task) { n in DeferredTask<Int?> { n * 2 } }.run()
        #expect(result == 10)
    }

    @Test func tOptionalFlatMapTNil() async {
        let task = DeferredTask<Int?> { nil }
        let result = await flatMapTDeferredTaskOptional(task) { n in DeferredTask<Int?> { n * 2 } }.run()
        #expect(result == nil)
    }

    // MARK: - TArray

    @Test func tArrayMapT() async {
        let task = DeferredTask<[Int]> { [1, 2, 3] }
        let result = await mapTDeferredTaskArray({ $0 * 2 }, task).run()
        #expect(result == [2, 4, 6])
    }

    @Test func tArrayFlatMapT() async {
        let task = DeferredTask<[Int]> { [1, 2] }
        let result = await flatMapTDeferredTaskArray(task) { n in DeferredTask<[Int]> { [n, n * 10] } }.run()
        #expect(result == [1, 10, 2, 20])
    }

    // MARK: - TResult

    @Test func tResultMapTSuccess() async {
        let task = DeferredTask<Result<Int, TestError>> { .success(5) }
        let result = await mapTDeferredTaskResult({ $0 * 2 }, task).run()
        #expect(result == .success(10))
    }

    @Test func tResultMapTFailure() async {
        let task = DeferredTask<Result<Int, TestError>> { .failure(.err) }
        let result = await mapTDeferredTaskResult({ $0 * 2 }, task).run()
        #expect(result == .failure(.err))
    }

    @Test func tResultFlatMapTSuccess() async {
        let task = DeferredTask<Result<Int, TestError>> { .success(5) }
        let result = await flatMapTDeferredTaskResult(task) { n in
            DeferredTask<Result<String, TestError>> { .success("v\(n)") }
        }.run()
        #expect(result == .success("v5"))
    }

    @Test func tResultFlatMapTFailure() async {
        let task = DeferredTask<Result<Int, TestError>> { .failure(.err) }
        let result = await flatMapTDeferredTaskResult(task) { n in
            DeferredTask<Result<String, TestError>> { .success("v\(n)") }
        }.run()
        #expect(result == .failure(.err))
    }

    // MARK: - Race

    @Test func raceIsLazy() async {
        nonisolated(unsafe) var ran = false
        let lhs = DeferredTask<Int> { ran = true; return 1 }
        let rhs = DeferredTask<Int> { 2 }
        let raced = race(lhs, rhs)
        #expect(!ran)
        _ = await raced.run()
        #expect(ran)
    }

    @Test func raceFastTaskWins() async {
        let fast = DeferredTask<Int> { 1 }
        let slow = DeferredTask<Int> {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            return 2
        }
        let result = await race(fast, slow).run()
        #expect(result == 1)
    }

    @Test func raceReturnsEitherOnTie() async {
        let lhs = DeferredTask<Int> { 1 }
        let rhs = DeferredTask<Int> { 2 }
        let result = await race(lhs, rhs).run()
        #expect(result == 1 || result == 2)
    }

    // MARK: - TOptional Alternative

    @Test func altOptionalFirstNonNilWins() async {
        let lhs = DeferredTask<Int?> { nil }
        let rhs = DeferredTask<Int?> { 42 }
        let result = await altDeferredTaskOptional(lhs, rhs).run()
        #expect(result == 42)
    }

    @Test func altOptionalFirstSomeBeatsNil() async {
        let lhs = DeferredTask<Int?> { 7 }
        let rhs = DeferredTask<Int?> { nil }
        let result = await altDeferredTaskOptional(lhs, rhs).run()
        #expect(result == 7)
    }

    @Test func altOptionalBothNilReturnsNil() async {
        let lhs = DeferredTask<Int?> { nil }
        let rhs = DeferredTask<Int?> { nil }
        let result = await altDeferredTaskOptional(lhs, rhs).run()
        #expect(result == nil)
    }

    @Test func altOptionalFasterTaskWins() async {
        let fast = DeferredTask<Int?> { 99 }
        let slow = DeferredTask<Int?> {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            return 1
        }
        let result = await altDeferredTaskOptional(fast, slow).run()
        #expect(result == 99)
    }

    @Test func altOptionalIsLazy() async {
        nonisolated(unsafe) var ran = false
        let lhs = DeferredTask<Int?> { ran = true; return 1 }
        let rhs = DeferredTask<Int?> { nil }
        let combined = altDeferredTaskOptional(lhs, rhs)
        #expect(!ran)
        _ = await combined.run()
        #expect(ran)
    }

    // MARK: - TResult Alternative

    @Test func altResultFirstSuccessWins() async {
        let lhs = DeferredTask<Result<Int, TestError>> { .failure(.err) }
        let rhs = DeferredTask<Result<Int, TestError>> { .success(42) }
        let result = await altDeferredTaskResult(lhs, rhs).run()
        #expect(result == .success(42))
    }

    @Test func altResultSuccessBeatsFailure() async {
        let lhs = DeferredTask<Result<Int, TestError>> { .success(7) }
        let rhs = DeferredTask<Result<Int, TestError>> { .failure(.err) }
        let result = await altDeferredTaskResult(lhs, rhs).run()
        #expect(result == .success(7))
    }

    @Test func altResultBothFailReturnsLastFailure() async {
        let lhs = DeferredTask<Result<Int, TestError>> { .failure(.err) }
        let rhs = DeferredTask<Result<Int, TestError>> { .failure(.err) }
        let result = await altDeferredTaskResult(lhs, rhs).run()
        #expect(result == .failure(.err))
    }

    @Test func altResultFasterSuccessWins() async {
        let fast = DeferredTask<Result<Int, TestError>> { .success(99) }
        let slow = DeferredTask<Result<Int, TestError>> {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            return .success(1)
        }
        let result = await altDeferredTaskResult(fast, slow).run()
        #expect(result == .success(99))
    }

    @Test func altResultIsLazy() async {
        nonisolated(unsafe) var ran = false
        let lhs = DeferredTask<Result<Int, TestError>> { ran = true; return .success(1) }
        let rhs = DeferredTask<Result<Int, TestError>> { .failure(.err) }
        let combined = altDeferredTaskResult(lhs, rhs)
        #expect(!ran)
        _ = await combined.run()
        #expect(ran)
    }

    // MARK: - join / void

    @Test func joinFreeFunction() async {
        let nested = DeferredTask<DeferredTask<Int>> { DeferredTask<Int> { 42 } }
        let result = await CoreFP.join(nested).run()
        #expect(result == 42)
    }

    @Test func voidFreeFunction() async {
        let task = DeferredTask<Int> { 99 }
        await CoreFP.void(task).run()
        // Void result — just verify it completes without error
    }
}
