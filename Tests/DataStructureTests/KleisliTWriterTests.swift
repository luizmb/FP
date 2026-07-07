// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct KleisliTWriterTests {
    enum TestError: Error, Equatable { case failure }

    // MARK: - [Writer<W, A>] — Array as outer, Writer as inner

    @Test func arrayTWriter() {
        let fn1: @Sendable (Int) -> [Writer<[String], Int>] = { n in [Writer(n * 2, ["fn1"])] }
        let fn2: @Sendable (Int) -> Writer<[String], String> = { n in Writer("\(n)", ["fn2"]) }

        let result = kleisliT(fn1, fn2)(5)
        #expect(result.count == 1)
        #expect(result[0].value == "10")
        #expect(result[0].log == ["fn1", "fn2"])

        let empty: @Sendable (Int) -> [Writer<[String], Int>] = const([])
        #expect(kleisliT(empty, fn2)(5).isEmpty)
    }

    // MARK: - Writer<W, A>? — Optional as outer, Writer as inner

    @Test func optionalTWriter() {
        let fn1: @Sendable (Int) -> Writer<[String], Int>? = { n in Writer(n * 2, ["fn1"]) }
        let fn2: @Sendable (Int) -> Writer<[String], String> = { n in Writer("\(n)", ["fn2"]) }

        if let writer = kleisliT(fn1, fn2)(5) {
            #expect(writer.value == "10")
            #expect(writer.log == ["fn1", "fn2"])
        } else {
            Issue.record("Expected non-nil Writer")
        }

        let none: @Sendable (Int) -> Writer<[String], Int>? = const(nil)
        #expect(kleisliT(none, fn2)(5) == nil)
    }

    // MARK: - Result<Writer<W, A>, E> — Result as outer, Writer as inner

    @Test func resultTWriter() {
        let fn1: @Sendable (Int) -> Result<Writer<[String], Int>, TestError> = { n in
            .success(Writer(n * 2, ["fn1"]))
        }
        let fn2: @Sendable (Int) -> Writer<[String], String> = { n in Writer("\(n)", ["fn2"]) }

        switch kleisliT(fn1, fn2)(5) {
        case let .success(writer):
            #expect(writer.value == "10")
            #expect(writer.log == ["fn1", "fn2"])

        case .failure:
            Issue.record("Expected .success")
        }

        let failing: @Sendable (Int) -> Result<Writer<[String], Int>, TestError> = const(.failure(.failure))
        switch kleisliT(failing, fn2)(5) {
        case .success:
            Issue.record("Expected .failure")

        case let .failure(error):
            #expect(error == .failure)
        }
    }

    // MARK: - Writer<W, [A]> — Writer as outer, Array as inner

    @Test func writerTArray() {
        let fn1: @Sendable (Int) -> Writer<[String], [Int]> = { n in Writer([n, n + 1], ["fn1"]) }
        let fn2: @Sendable (Int) -> Writer<[String], [String]> = { n in Writer(["\(n)"], ["fn2(\(n))"]) }

        let result = kleisliT(fn1, fn2)(5)
        #expect(result.value == ["5", "6"])
        #expect(result.log == ["fn1", "fn2(5)", "fn2(6)"])

        let empty: @Sendable (Int) -> Writer<[String], [Int]> = const(Writer([], ["fn1"]))
        let emptyResult = kleisliT(empty, fn2)(5)
        #expect(emptyResult.value.isEmpty)
        #expect(emptyResult.log == ["fn1"])
    }

    // MARK: - Writer<W, Either<L, A>> — Writer as outer, Either as inner

    @Test func writerTEither() {
        let fn1: @Sendable (Int) -> Writer<[String], Either<String, Int>> = { n in
            Writer(.right(n * 2), ["fn1"])
        }
        let fn2: @Sendable (Int) -> Writer<[String], Either<String, String>> = { n in
            Writer(.right("\(n)"), ["fn2"])
        }

        let result = kleisliT(fn1, fn2)(5)
        #expect(result.value == .right("10"))
        #expect(result.log == ["fn1", "fn2"])

        let failing: @Sendable (Int) -> Writer<[String], Either<String, Int>> = const(
            Writer(.left("boom"), ["fn1"])
        )
        let leftResult = kleisliT(failing, fn2)(5)
        #expect(leftResult.value == .left("boom"))
        #expect(leftResult.log == ["fn1"])
    }

    // MARK: - Writer<W, A?> — Writer as outer, Optional as inner

    @Test func writerTOptional() {
        let fn1: @Sendable (Int) -> Writer<[String], Int?> = { n in Writer(n * 2, ["fn1"]) }
        let fn2: @Sendable (Int) -> Writer<[String], String?> = { n in Writer("\(n)", ["fn2"]) }

        let result = kleisliT(fn1, fn2)(5)
        #expect(result.value == "10")
        #expect(result.log == ["fn1", "fn2"])

        let none: @Sendable (Int) -> Writer<[String], Int?> = const(Writer(nil, ["fn1"]))
        let nilResult = kleisliT(none, fn2)(5)
        #expect(nilResult.value == nil)
        #expect(nilResult.log == ["fn1"])
    }

    // MARK: - Writer<W, Reader<Env, A>> — Writer as outer, Reader as inner

    @Test func writerTReader() {
        let fn1: @Sendable (Int) -> Writer<[String], Reader<Int, Int>> = { n in
            Writer(Reader { env in n + env }, ["fn1"])
        }
        let fn2: @Sendable (Int) -> Writer<[String], Reader<Int, String>> = { n in
            Writer(Reader { env in "\(n * env)" }, ["fn2"])
        }

        let result = kleisliT(fn1, fn2)(5)
        #expect(result.value.runReader(2) == "14")
        // Reader is lazy — flatMapT keeps the outer log only; fn2's log is discarded
        #expect(result.log == ["fn1"])
    }

    // MARK: - Writer<W, Result<A, E>> — Writer as outer, Result as inner

    @Test func writerTResult() {
        let fn1: @Sendable (Int) -> Writer<[String], Result<Int, TestError>> = { n in
            Writer(.success(n * 2), ["fn1"])
        }
        let fn2: @Sendable (Int) -> Writer<[String], Result<String, TestError>> = { n in
            Writer(.success("\(n)"), ["fn2"])
        }

        let result = kleisliT(fn1, fn2)(5)
        #expect(result.value == .success("10"))
        #expect(result.log == ["fn1", "fn2"])

        let failing: @Sendable (Int) -> Writer<[String], Result<Int, TestError>> = const(
            Writer(.failure(.failure), ["fn1"])
        )
        let failureResult = kleisliT(failing, fn2)(5)
        #expect(failureResult.value == .failure(.failure))
        #expect(failureResult.log == ["fn1"])
    }

    // MARK: - Writer<W, Stateful<S, A>> — Writer as outer, Stateful as inner

    @Test func writerTStateful() {
        let fn1: @Sendable (Int) -> Writer<[String], Stateful<Int, Int>> = { n in
            Writer(
                Stateful { state in
                    state += 1
                    return n * 2
                },
                ["fn1"]
            )
        }
        let fn2: @Sendable (Int) -> Writer<[String], Stateful<Int, String>> = { n in
            Writer(
                Stateful { state in
                    state += 10
                    return "\(n)"
                },
                ["fn2"]
            )
        }

        let result = kleisliT(fn1, fn2)(5)
        let (value, finalState) = result.value.runStateful(0)
        #expect(value == "10")
        #expect(finalState == 11)
        // Stateful is lazy — flatMapT keeps the outer log only; fn2's log is discarded
        #expect(result.log == ["fn1"])
    }
}
