import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct StatefulTResultOperatorsTests {
    enum TestError: Error, Equatable { case failure }

    @Test func fmapSuccess() {
        let s = Stateful<Int, Result<Int, TestError>>.pure(.success(5))
        let result = { $0 * 2 } <£^> s
        #expect(result.eval(0) == .success(10))
    }

    @Test func flippedFmapSuccess() {
        let s = Stateful<Int, Result<Int, TestError>>.pure(.success(5))
        let result = s <&^> { $0 * 2 }
        #expect(result.eval(0) == .success(10))
    }

    @Test func fmapFailure() {
        let s = Stateful<Int, Result<Int, TestError>>.pure(.failure(.failure))
        let result = { $0 * 2 } <£^> s
        #expect(result.eval(0) == .failure(.failure))
    }

    @Test func apply() {
        let sf = Stateful<Int, Result<(Int) -> String, TestError>>.pure(.success { "\($0)" })
        let sa = Stateful<Int, Result<Int, TestError>>.pure(.success(9))
        let result = sf <*> sa
        #expect(result.eval(0) == .success("9"))
    }

    @Test func seqRight() {
        let lhs = Stateful<Int, Result<Int, TestError>>.pure(.success(1))
        let rhs = Stateful<Int, Result<String, TestError>>.pure(.success("b"))
        let result = lhs *> rhs
        #expect(result.eval(0) == .success("b"))
    }

    @Test func seqLeft() {
        let lhs = Stateful<Int, Result<Int, TestError>>.pure(.success(1))
        let rhs = Stateful<Int, Result<String, TestError>>.pure(.success("b"))
        let result = lhs <* rhs
        #expect(result.eval(0) == .success(1))
    }

    @Test func bind() {
        let s = Stateful<Int, Result<Int, TestError>>.pure(.success(5))
        let result = s >>- { n in Stateful<Int, Result<String, TestError>>.pure(.success("\(n)")) }
        #expect(result.eval(0) == .success("5"))
    }

    @Test func bindFailure() {
        let s = Stateful<Int, Result<Int, TestError>>.pure(.failure(.failure))
        let result = s >>- { n in Stateful<Int, Result<String, TestError>>.pure(.success("\(n)")) }
        #expect(result.eval(0) == .failure(.failure))
    }

    @Test func kleisli() {
        let f: (Int) -> Stateful<Int, Result<Int, TestError>> = { n in .pure(.success(n + 1)) }
        let g: (Int) -> Stateful<Int, Result<String, TestError>> = { n in .pure(.success("\(n)")) }
        let result = (f >=> g)(4)
        #expect(result.eval(0) == .success("5"))
    }
}
