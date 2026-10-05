// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct KleisliTWriterTests {
    enum TestError: Error, Equatable { case failure }

    // MARK: - [Writer<W, A>] — Array as outer, Writer as inner

    @Test func arrayTWriter() {
        let fn1: @Sendable (Int) -> ArrayTWriter<[String], Int> = { n in ArrayTWriter([Writer(n * 2, ["fn1"])]) }
        let fn2: @Sendable (Int) -> ArrayTWriter<[String], String> = { n in ArrayTWriter([Writer("\(n)", ["fn2"])]) }

        let result = ArrayTWriter.kleisli(fn1, fn2)(5).rawValue
        #expect(result.count == 1)
        #expect(result[0].value == "10")
        #expect(result[0].log == ["fn1", "fn2"])

        let empty: @Sendable (Int) -> ArrayTWriter<[String], Int> = const(ArrayTWriter([]))
        #expect(ArrayTWriter.kleisli(empty, fn2)(5).rawValue.isEmpty)
    }

    // MARK: - Writer<W, A>? — Optional as outer, Writer as inner

    @Test func optionalTWriter() {
        let fn1: @Sendable (Int) -> OptionalTWriter<[String], Int> = { n in OptionalTWriter(Writer(n * 2, ["fn1"])) }
        let fn2: @Sendable (Int) -> OptionalTWriter<[String], String> = { n in OptionalTWriter(Writer("\(n)", ["fn2"])) }

        if let writer = OptionalTWriter.kleisli(fn1, fn2)(5).rawValue {
            #expect(writer.value == "10")
            #expect(writer.log == ["fn1", "fn2"])
        } else {
            Issue.record("Expected non-nil Writer")
        }

        let none: @Sendable (Int) -> OptionalTWriter<[String], Int> = const(OptionalTWriter(nil))
        #expect(OptionalTWriter.kleisli(none, fn2)(5).rawValue == nil)
    }

    // MARK: - Result<Writer<W, A>, E> — Result as outer, Writer as inner

    @Test func resultTWriter() {
        let fn1: @Sendable (Int) -> ResultTWriter<TestError, [String], Int> = { n in
            ResultTWriter(.success(Writer(n * 2, ["fn1"])))
        }
        let fn2: @Sendable (Int) -> ResultTWriter<TestError, [String], String> = { n in ResultTWriter(.success(Writer("\(n)", ["fn2"]))) }

        switch ResultTWriter.kleisli(fn1, fn2)(5).rawValue {
        case let .success(writer):
            #expect(writer.value == "10")
            #expect(writer.log == ["fn1", "fn2"])

        case .failure:
            Issue.record("Expected .success")
        }

        let failing: @Sendable (Int) -> ResultTWriter<TestError, [String], Int> = const(ResultTWriter(.failure(.failure)))
        switch ResultTWriter.kleisli(failing, fn2)(5).rawValue {
        case .success:
            Issue.record("Expected .failure")

        case let .failure(error):
            #expect(error == .failure)
        }
    }

    // MARK: - Writer<W, Either<L, A>> — WriterTEither

    @Test func writerTEither() {
        let fn1: @Sendable (Int) -> WriterTEither<[String], String, Int> = { n in
            WriterTEither(Writer(.right(n * 2), ["fn1"]))
        }
        let fn2: @Sendable (Int) -> WriterTEither<[String], String, String> = { n in
            WriterTEither(Writer(.right("\(n)"), ["fn2"]))
        }

        let result = WriterTEither.kleisli(fn1, fn2)(5).rawValue
        #expect(result.value == .right("10"))
        #expect(result.log == ["fn1", "fn2"])

        let failing: @Sendable (Int) -> WriterTEither<[String], String, Int> = const(
            WriterTEither(Writer(.left("boom"), ["fn1"]))
        )
        let leftResult = WriterTEither.kleisli(failing, fn2)(5).rawValue
        #expect(leftResult.value == .left("boom"))
        #expect(leftResult.log == ["fn1"])
    }

    // MARK: - Writer<W, A?> — WriterTOptional

    @Test func writerTOptional() {
        let fn1: @Sendable (Int) -> WriterTOptional<[String], Int> = { n in WriterTOptional(Writer(n * 2, ["fn1"])) }
        let fn2: @Sendable (Int) -> WriterTOptional<[String], String> = { n in WriterTOptional(Writer("\(n)", ["fn2"])) }

        let result = WriterTOptional.kleisli(fn1, fn2)(5).rawValue
        #expect(result.value == "10")
        #expect(result.log == ["fn1", "fn2"])

        let none: @Sendable (Int) -> WriterTOptional<[String], Int> = const(WriterTOptional(Writer(nil, ["fn1"])))
        let nilResult = WriterTOptional.kleisli(none, fn2)(5).rawValue
        #expect(nilResult.value == nil)
        #expect(nilResult.log == ["fn1"])
    }

    // MARK: - Writer<W, Result<A, E>> — WriterTResult

    @Test func writerTResult() {
        let fn1: @Sendable (Int) -> WriterTResult<[String], TestError, Int> = { n in
            WriterTResult(Writer(.success(n * 2), ["fn1"]))
        }
        let fn2: @Sendable (Int) -> WriterTResult<[String], TestError, String> = { n in
            WriterTResult(Writer(.success("\(n)"), ["fn2"]))
        }

        let result = WriterTResult.kleisli(fn1, fn2)(5).rawValue
        #expect(result.value == .success("10"))
        #expect(result.log == ["fn1", "fn2"])

        let failing: @Sendable (Int) -> WriterTResult<[String], TestError, Int> = const(
            WriterTResult(Writer(.failure(.failure), ["fn1"]))
        )
        let failureResult = WriterTResult.kleisli(failing, fn2)(5).rawValue
        #expect(failureResult.value == .failure(.failure))
        #expect(failureResult.log == ["fn1"])
    }
}
