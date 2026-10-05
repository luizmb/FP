// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ResultTStatefulOperatorsTests {
    enum TestError: Error, Equatable { case failure }

    @Test func apply() {
        let rf: Result<Stateful<Int, @Sendable (Int) -> String>, TestError> = .success(.pure { "\($0)" })
        let ra: Result<Stateful<Int, Int>, TestError> = .success(.get)
        let result = (rf.resultT <*> ra.resultT).rawValue
        #expect(Result.prism.success.preview(result)?.eval(5) == "5")
    }

    @Test func applyFailure() {
        let rf: Result<Stateful<Int, @Sendable (Int) -> String>, TestError> = .failure(.failure)
        let ra: Result<Stateful<Int, Int>, TestError> = .success(.pure(5))
        let result = (rf.resultT <*> ra.resultT).rawValue
        if case let .failure(e) = result { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }

    @Test func seqRight() {
        let lhs: Result<Stateful<Int, Int>, TestError> = .success(.pure(1))
        let rhs: Result<Stateful<Int, String>, TestError> = .success(.pure("hello"))
        let result = (lhs.resultT *> rhs.resultT).rawValue
        #expect(Result.prism.success.preview(result)?.eval(0) == "hello")
    }

    @Test func seqLeft() {
        let lhs: Result<Stateful<Int, Int>, TestError> = .success(.pure(99))
        let rhs: Result<Stateful<Int, String>, TestError> = .success(.pure("ignored"))
        let result = (lhs.resultT <* rhs.resultT).rawValue
        #expect(Result.prism.success.preview(result)?.eval(0) == 99)
    }
}
