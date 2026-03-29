import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterTResultOperatorsTests {
    enum TestError: Error, Equatable { case failure }

    @Test func fmapSuccess() {
        let w = Writer<[String], Result<Int, TestError>>(.success(5), ["log"])
        let result = { $0 * 2 } <£^> w
        #expect(result.value == .success(10))
        #expect(result.log == ["log"])
    }

    @Test func flippedFmapSuccess() {
        let w = Writer<[String], Result<Int, TestError>>(.success(5), ["log"])
        let result = w <&^> { $0 * 2 }
        #expect(result.value == .success(10))
        #expect(result.log == ["log"])
    }

    @Test func fmapFailure() {
        let w = Writer<[String], Result<Int, TestError>>(.failure(.failure), ["log"])
        let result = { $0 * 2 } <£^> w
        #expect(result.value == .failure(.failure))
        #expect(result.log == ["log"])
    }

    @Test func apply() {
        let wf = Writer<[String], Result<(Int) -> String, TestError>>(.success { "\($0)" }, ["fn"])
        let wa = Writer<[String], Result<Int, TestError>>(.success(9), ["val"])
        let result = wf <*> wa
        #expect(result.value == .success("9"))
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs = Writer<[String], Result<Int, TestError>>(.success(1), ["a"])
        let rhs = Writer<[String], Result<String, TestError>>(.success("b"), ["b"])
        let result = lhs *> rhs
        #expect(result.value == .success("b"))
        #expect(result.log == ["a", "b"])
    }

    @Test func bind() {
        let w = Writer<[String], Result<Int, TestError>>(.success(5), ["outer"])
        let result = w >>- { n in Writer<[String], Result<String, TestError>>(.success("\(n)"), ["inner"]) }
        #expect(result.value == .success("5"))
        #expect(result.log == ["outer", "inner"])
    }

    @Test func kleisli() {
        let f: (Int) -> Writer<[String], Result<Int, TestError>> = { n in Writer(.success(n + 1), ["f"]) }
        let g: (Int) -> Writer<[String], Result<String, TestError>> = { n in Writer(.success("\(n)"), ["g"]) }
        let result = (f >=> g)(4)
        #expect(result.value == .success("5"))
        #expect(result.log == ["f", "g"])
    }
}
