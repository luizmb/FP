import CoreFP
import DataStructure
import DataStructureOperators
import Testing
import CoreFPOperators

@Suite struct ResultTWriterOperatorsTests {
    enum TestError: Error, Equatable { case failure }

    @Test func fmapSuccess() {
        let result: Result<Writer<[String], Int>, TestError> = .success(Writer(5, ["x"]))
        let mapped = { $0 * 2 } <£^> result
        #expect(mapped.success?.value == 10)
        #expect(mapped.success?.log == ["x"])
    }

    @Test func flippedFmapSuccess() {
        let result: Result<Writer<[String], Int>, TestError> = .success(Writer(5, ["x"]))
        let mapped = result <&^> { $0 * 2 }
        #expect(mapped.success?.value == 10)
        #expect(mapped.success?.log == ["x"])
    }

    @Test func fmapFailure() {
        let result: Result<Writer<[String], Int>, TestError> = .failure(.failure)
        let mapped: Result<Writer<[String], Int>, TestError> = { $0 * 2 } <£^> result
        if case .failure(let e) = mapped { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }

    @Test func bindSuccess() {
        let result: Result<Writer<[String], Int>, TestError> = .success(Writer(5, ["outer"]))
        let bound = result >>- { n in Writer<[String], String>("\(n)", ["inner"]) }
        #expect(bound.success?.value == "5")
        #expect(bound.success?.log == ["outer", "inner"])
    }

    @Test func bindFailure() {
        let result: Result<Writer<[String], Int>, TestError> = .failure(.failure)
        let bound = result >>- { n in Writer<[String], String>("\(n)", ["inner"]) }
        if case .failure(let e) = bound { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }

    @Test func kleisli() {
        let f: (Int) -> Result<Writer<[String], Int>, TestError> = { n in .success(Writer(n + 1, ["f"])) }
        let g: (Int) -> Writer<[String], String> = { n in Writer("\(n)", ["g"]) }
        let result = (f >=> g)(4)
        #expect(result.success?.value == "5")
        #expect(result.success?.log == ["f", "g"])
    }

    @Test func apply() {
        let rf: Result<Writer<[String], (Int) -> String>, TestError> = .success(Writer({ "\($0)" }, ["fn"]))
        let ra: Result<Writer<[String], Int>, TestError> = .success(Writer(7, ["val"]))
        let result = rf <*> ra
        #expect(result.success?.value == "7")
        #expect(result.success?.log == ["fn", "val"])
    }

    @Test func applyFailure() {
        let rf: Result<Writer<[String], (Int) -> String>, TestError> = .failure(.failure)
        let ra: Result<Writer<[String], Int>, TestError> = .success(Writer(7, ["val"]))
        let result = rf <*> ra
        if case .failure(let e) = result { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }

    @Test func seqRight() {
        let lhs: Result<Writer<[String], Int>, TestError> = .success(Writer(1, ["a"]))
        let rhs: Result<Writer<[String], String>, TestError> = .success(Writer("hello", ["b"]))
        let result = lhs *> rhs
        #expect(result.success?.value == "hello")
        #expect(result.success?.log == ["a", "b"])
    }

    @Test func seqLeft() {
        let lhs: Result<Writer<[String], Int>, TestError> = .success(Writer(99, ["a"]))
        let rhs: Result<Writer<[String], String>, TestError> = .success(Writer("ignored", ["b"]))
        let result = lhs <* rhs
        #expect(result.success?.value == 99)
        #expect(result.success?.log == ["a", "b"])
    }
}
