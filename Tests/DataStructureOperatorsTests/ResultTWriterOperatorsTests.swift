// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ResultTWriterOperatorsTests {
    enum TestError: Error, Equatable { case failure }

    @Test func bindSuccess() {
        let result: Result<Writer<[String], Int>, TestError> = .success(Writer(5, ["outer"]))
        let fn: @Sendable (Int) -> Result<Writer<[String], String>, TestError> = { n in .success(Writer("\(n)", ["inner"])) }
        #expect((result >>- fn) == .success(Writer("5", ["outer", "inner"])))
    }

    @Test func bindFailure() {
        let result: Result<Writer<[String], Int>, TestError> = .failure(.failure)
        let fn: @Sendable (Int) -> Result<Writer<[String], String>, TestError> = { n in .success(Writer("\(n)", ["inner"])) }
        #expect((result >>- fn) == .failure(.failure))
    }

    @Test func bindContinuationFails() {
        let result: Result<Writer<[String], Int>, TestError> = .success(Writer(5, ["outer"]))
        let fn: @Sendable (Int) -> Result<Writer<[String], String>, TestError> = const(.failure(.failure))
        #expect((result >>- fn) == .failure(.failure))
    }

    @Test func flippedBind() {
        let result: Result<Writer<[String], Int>, TestError> = .success(Writer(5, ["outer"]))
        let fn: @Sendable (Int) -> Result<Writer<[String], String>, TestError> = { n in .success(Writer("\(n)", ["inner"])) }
        #expect((fn -<< result) == .success(Writer("5", ["outer", "inner"])))
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> Result<Writer<[String], Int>, TestError> = { n in .success(Writer(n + 1, ["f"])) }
        let g: @Sendable (Int) -> Result<Writer<[String], String>, TestError> = { n in .success(Writer("\(n)", ["g"])) }
        #expect((f >=> g)(4) == .success(Writer("5", ["f", "g"])))
    }

    @Test func reverseKleisli() {
        let f: @Sendable (Int) -> Result<Writer<[String], Int>, TestError> = { n in .success(Writer(n + 1, ["f"])) }
        let g: @Sendable (Int) -> Result<Writer<[String], String>, TestError> = { n in .success(Writer("\(n)", ["g"])) }
        #expect((g <=< f)(4) == .success(Writer("5", ["f", "g"])))
    }

    @Test func apply() {
        let rf: Result<Writer<[String], @Sendable (Int) -> String>, TestError> = .success(Writer({ @Sendable in "\($0)" }, ["fn"]))
        let ra: Result<Writer<[String], Int>, TestError> = .success(Writer(7, ["val"]))
        let result = rf <*> ra
        #expect(Result.prism.success.preview(result)?.value == "7")
        #expect(Result.prism.success.preview(result)?.log == ["fn", "val"])
    }

    @Test func applyFailure() {
        let rf: Result<Writer<[String], @Sendable (Int) -> String>, TestError> = .failure(.failure)
        let ra: Result<Writer<[String], Int>, TestError> = .success(Writer(7, ["val"]))
        let result = rf <*> ra
        if case let .failure(e) = result { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }

    @Test func seqRight() {
        let lhs: Result<Writer<[String], Int>, TestError> = .success(Writer(1, ["a"]))
        let rhs: Result<Writer<[String], String>, TestError> = .success(Writer("hello", ["b"]))
        let result = lhs *> rhs
        #expect(Result.prism.success.preview(result)?.value == "hello")
        #expect(Result.prism.success.preview(result)?.log == ["a", "b"])
    }

    @Test func seqLeft() {
        let lhs: Result<Writer<[String], Int>, TestError> = .success(Writer(99, ["a"]))
        let rhs: Result<Writer<[String], String>, TestError> = .success(Writer("ignored", ["b"]))
        let result = lhs <* rhs
        #expect(Result.prism.success.preview(result)?.value == 99)
        #expect(Result.prism.success.preview(result)?.log == ["a", "b"])
    }
}
