// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ResultTWriterOperatorsTests {
    enum TestError: Error, Equatable { case failure }

    @Test func fmapSuccess() {
        let result: Result<Writer<[String], Int>, TestError> = .success(Writer(5, ["x"]))
        let mapped = { $0 * 2 } <£^> result
        #expect(Result.prism.success.preview(mapped)?.value == 10)
        #expect(Result.prism.success.preview(mapped)?.log == ["x"])
    }

    @Test func flippedFmapSuccess() {
        let result: Result<Writer<[String], Int>, TestError> = .success(Writer(5, ["x"]))
        let mapped = result <&^> { $0 * 2 }
        #expect(Result.prism.success.preview(mapped)?.value == 10)
        #expect(Result.prism.success.preview(mapped)?.log == ["x"])
    }

    @Test func fmapFailure() {
        let result: Result<Writer<[String], Int>, TestError> = .failure(.failure)
        let mapped: Result<Writer<[String], Int>, TestError> = { $0 * 2 } <£^> result
        if case let .failure(e) = mapped { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }

    @Test func bindSuccess() {
        let result: Result<Writer<[String], Int>, TestError> = .success(Writer(5, ["outer"]))
        let bound = result >>- { n in Writer<[String], String>("\(n)", ["inner"]) }
        #expect(Result.prism.success.preview(bound)?.value == "5")
        #expect(Result.prism.success.preview(bound)?.log == ["outer", "inner"])
    }

    @Test func bindFailure() {
        let result: Result<Writer<[String], Int>, TestError> = .failure(.failure)
        let bound = result >>- { n in Writer<[String], String>("\(n)", ["inner"]) }
        if case let .failure(e) = bound { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> Result<Writer<[String], Int>, TestError> = { n in .success(Writer(n + 1, ["f"])) }
        let g: @Sendable (Int) -> Writer<[String], String> = { n in Writer("\(n)", ["g"]) }
        let result = (f >=> g)(4)
        #expect(Result.prism.success.preview(result)?.value == "5")
        #expect(Result.prism.success.preview(result)?.log == ["f", "g"])
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
