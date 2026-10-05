// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct ResultTStatefulApplicativeTests {
    enum TestError: Error, Equatable { case failure }

    // MARK: - Result<Stateful<S, A>, E> — Result as outer, Stateful as inner

    @Test func applyBothSuccess() {
        let rf: Result<Stateful<Int, @Sendable (Int) -> String>, TestError> = .success(.pure { "\($0)" })
        let ra: Result<Stateful<Int, Int>, TestError> = .success(.get)
        let result = ResultTStateful.apply(rf.resultT, ra.resultT).rawValue
        #expect(Result.prism.success.preview(result)?.eval(5) == "5")
    }

    @Test func applyFailureFn() {
        let rf: Result<Stateful<Int, @Sendable (Int) -> String>, TestError> = .failure(.failure)
        let ra: Result<Stateful<Int, Int>, TestError> = .success(.pure(5))
        let result = ResultTStateful.apply(rf.resultT, ra.resultT).rawValue
        if case let .failure(e) = result { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }

    @Test func applyFailureVal() {
        let rf: Result<Stateful<Int, @Sendable (Int) -> String>, TestError> = .success(.pure { "\($0)" })
        let ra: Result<Stateful<Int, Int>, TestError> = .failure(.failure)
        let result = ResultTStateful.apply(rf.resultT, ra.resultT).rawValue
        if case let .failure(e) = result { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }

    @Test func seqRightBothSuccess() {
        let lhs: Result<Stateful<Int, Int>, TestError> = .success(.pure(1))
        let rhs: Result<Stateful<Int, String>, TestError> = .success(.pure("hello"))
        let result = lhs.resultT.seqRight(rhs.resultT).rawValue
        #expect(Result.prism.success.preview(result)?.eval(0) == "hello")
    }

    @Test func seqRightFailure() {
        let lhs: Result<Stateful<Int, Int>, TestError> = .failure(.failure)
        let rhs: Result<Stateful<Int, String>, TestError> = .success(.pure("hello"))
        let result = lhs.resultT.seqRight(rhs.resultT).rawValue
        if case let .failure(e) = result { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }

    @Test func seqLeftBothSuccess() {
        let lhs: Result<Stateful<Int, Int>, TestError> = .success(.pure(99))
        let rhs: Result<Stateful<Int, String>, TestError> = .success(.pure("ignored"))
        let result = lhs.resultT.seqLeft(rhs.resultT).rawValue
        #expect(Result.prism.success.preview(result)?.eval(0) == 99)
    }

    @Test func seqLeftFailureRight() {
        let lhs: Result<Stateful<Int, Int>, TestError> = .success(.pure(99))
        let rhs: Result<Stateful<Int, String>, TestError> = .failure(.failure)
        let result = lhs.resultT.seqLeft(rhs.resultT).rawValue
        if case let .failure(e) = result { #expect(e == .failure) } else { Issue.record("Expected .failure") }
    }
}
