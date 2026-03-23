import DataStructureOperators
import DataStructure
import Testing
import CoreFPOperators
import CoreFP

@Suite struct ResultTStatefulOperatorsTests {

    enum TestError: Error, Equatable { case failure }

    @Test func fmapSuccess() {
        let result: Result<Stateful<Int, Int>, TestError> = .success(.get)
        let mapped = { $0 * 2 } <£^> result
        #expect(mapped.success?.eval(5) == 10)
    }

    @Test func fmapFailure() {
        let result: Result<Stateful<Int, Int>, TestError> = .failure(.failure)
        let mapped: Result<Stateful<Int, Int>, TestError> = { $0 * 2 } <£^> result
        if case .failure(let e) = mapped { #expect(e == .failure) }
        else { Issue.record("Expected .failure") }
    }

    @Test func bindSuccess() {
        let result: Result<Stateful<Int, Int>, TestError> = .success(.get)
        let bound = result >>- { n in Stateful<Int, String>.pure("\(n)") }
        #expect(bound.success?.eval(3) == "3")
    }

    @Test func bindFailure() {
        let result: Result<Stateful<Int, Int>, TestError> = .failure(.failure)
        let bound = result >>- { n in Stateful<Int, String>.pure("\(n)") }
        if case .failure(let e) = bound { #expect(e == .failure) }
        else { Issue.record("Expected .failure") }
    }

    @Test func kleisli() {
        let f: (Int) -> Result<Stateful<Int, Int>, TestError> = { n in .success(.pure(n + 1)) }
        let g: (Int) -> Stateful<Int, String> = { n in .pure("\(n)") }
        let result = (f >=> g)(4)
        #expect(result.success?.eval(0) == "5")
    }

    @Test func apply() {
        let rf: Result<Stateful<Int, (Int) -> String>, TestError> = .success(.pure({ "\($0)" }))
        let ra: Result<Stateful<Int, Int>, TestError> = .success(.get)
        let result = rf <*> ra
        #expect(result.success?.eval(5) == "5")
    }

    @Test func applyFailure() {
        let rf: Result<Stateful<Int, (Int) -> String>, TestError> = .failure(.failure)
        let ra: Result<Stateful<Int, Int>, TestError> = .success(.pure(5))
        let result = rf <*> ra
        if case .failure(let e) = result { #expect(e == .failure) }
        else { Issue.record("Expected .failure") }
    }

    @Test func seqRight() {
        let lhs: Result<Stateful<Int, Int>, TestError> = .success(.pure(1))
        let rhs: Result<Stateful<Int, String>, TestError> = .success(.pure("hello"))
        let result = lhs *> rhs
        #expect(result.success?.eval(0) == "hello")
    }

    @Test func seqLeft() {
        let lhs: Result<Stateful<Int, Int>, TestError> = .success(.pure(99))
        let rhs: Result<Stateful<Int, String>, TestError> = .success(.pure("ignored"))
        let result = lhs <* rhs
        #expect(result.success?.eval(0) == 99)
    }
}
