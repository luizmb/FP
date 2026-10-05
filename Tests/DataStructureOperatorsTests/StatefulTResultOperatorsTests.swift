// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct StatefulTResultOperatorsTests {
    enum TestError: Error, Equatable { case failure }

    @Test func apply() {
        let sf = Stateful<Int, Result<@Sendable (Int) -> String, TestError>>.pure(.success { "\($0)" })
        let sa = Stateful<Int, Result<Int, TestError>>.pure(.success(9))
        let result = sf.statefulT <*> sa.statefulT
        #expect(result.rawValue.eval(0) == .success("9"))
    }

    @Test func seqRight() {
        let lhs = Stateful<Int, Result<Int, TestError>>.pure(.success(1))
        let rhs = Stateful<Int, Result<String, TestError>>.pure(.success("b"))
        let result = lhs.statefulT *> rhs.statefulT
        #expect(result.rawValue.eval(0) == .success("b"))
    }

    @Test func seqLeft() {
        let lhs = Stateful<Int, Result<Int, TestError>>.pure(.success(1))
        let rhs = Stateful<Int, Result<String, TestError>>.pure(.success("b"))
        let result = lhs.statefulT <* rhs.statefulT
        #expect(result.rawValue.eval(0) == .success(1))
    }

    @Test func bind() {
        let s = Stateful<Int, Result<Int, TestError>>.pure(.success(5))
        let result = s.statefulT >>- { n in Stateful<Int, Result<String, TestError>>.pure(.success("\(n)")).statefulT }
        #expect(result.rawValue.eval(0) == .success("5"))
    }

    @Test func bindFailure() {
        let s = Stateful<Int, Result<Int, TestError>>.pure(.failure(.failure))
        let result = s.statefulT >>- { n in Stateful<Int, Result<String, TestError>>.pure(.success("\(n)")).statefulT }
        #expect(result.rawValue.eval(0) == .failure(.failure))
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> StatefulTResult<Int, TestError, Int> = { n in StatefulTResult(.pure(.success(n + 1))) }
        let g: @Sendable (Int) -> StatefulTResult<Int, TestError, String> = { n in StatefulTResult(.pure(.success("\(n)"))) }
        let result = (f >=> g)(4)
        #expect(result.rawValue.eval(0) == .success("5"))
    }
}
