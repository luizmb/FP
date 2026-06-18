// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct ResultTWriterApplicativeTests {
    enum TestError: Error, Equatable { case failure }

    // MARK: - Result<Writer<W, A>, E> — Result as outer, Writer as inner

    @Test func applyBothSuccess() {
        let rf: Result<Writer<[String], @Sendable (Int) -> String>, TestError> = .success(Writer({ @Sendable in "\($0)" }, ["fn"]))
        let ra: Result<Writer<[String], Int>, TestError> = .success(Writer(7, ["val"]))
        let result = applyResultWriter(rf, ra)
        #expect(Result.prism.success.preview(result)?.value == "7")
        #expect(Result.prism.success.preview(result)?.log == ["fn", "val"])
    }

    @Test func applyFailureFn() {
        let rf: Result<Writer<[String], @Sendable (Int) -> String>, TestError> = .failure(.failure)
        let ra: Result<Writer<[String], Int>, TestError> = .success(Writer(7, ["val"]))
        let result = applyResultWriter(rf, ra)
        if case .failure(let e) = result { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }

    @Test func applyFailureVal() {
        let rf: Result<Writer<[String], @Sendable (Int) -> String>, TestError> = .success(Writer({ @Sendable in "\($0)" }, ["fn"]))
        let ra: Result<Writer<[String], Int>, TestError> = .failure(.failure)
        let result = applyResultWriter(rf, ra)
        if case .failure(let e) = result { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }

    @Test func seqRightBothSuccess() {
        let lhs: Result<Writer<[String], Int>, TestError> = .success(Writer(1, ["a"]))
        let rhs: Result<Writer<[String], String>, TestError> = .success(Writer("hello", ["b"]))
        let result = seqRightResultWriter(lhs, rhs)
        #expect(Result.prism.success.preview(result)?.value == "hello")
        #expect(Result.prism.success.preview(result)?.log == ["a", "b"])
    }

    @Test func seqRightFailure() {
        let lhs: Result<Writer<[String], Int>, TestError> = .failure(.failure)
        let rhs: Result<Writer<[String], String>, TestError> = .success(Writer("hello", ["b"]))
        let result = seqRightResultWriter(lhs, rhs)
        if case .failure(let e) = result { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }

    @Test func seqLeftBothSuccess() {
        let lhs: Result<Writer<[String], Int>, TestError> = .success(Writer(99, ["a"]))
        let rhs: Result<Writer<[String], String>, TestError> = .success(Writer("ignored", ["b"]))
        let result = seqLeftResultWriter(lhs, rhs)
        #expect(Result.prism.success.preview(result)?.value == 99)
        #expect(Result.prism.success.preview(result)?.log == ["a", "b"])
    }

    @Test func seqLeftFailureRight() {
        let lhs: Result<Writer<[String], Int>, TestError> = .success(Writer(99, ["a"]))
        let rhs: Result<Writer<[String], String>, TestError> = .failure(.failure)
        let result = seqLeftResultWriter(lhs, rhs)
        if case .failure(let e) = result { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }
}
