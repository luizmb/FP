// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct StatefulTResultTests {
    enum TestError: Error, Equatable { case failure }

    // MARK: - Stateful<S, Result<A, E>> — State as outer, Result as inner

    @Test func mapSuccess() {
        let s = Stateful<Int, Result<Int, TestError>>.pure(.success(5))
        let mapped = s.statefulT.map { $0 * 2 }
        #expect(mapped.rawValue.eval(0) == .success(10))
    }

    @Test func mapFailure() {
        let s = Stateful<Int, Result<Int, TestError>>.pure(.failure(.failure))
        let mapped = s.statefulT.map { $0 * 2 }
        #expect(mapped.rawValue.eval(0) == .failure(.failure))
    }

    @Test func flatMapSuccess() {
        let s = Stateful<Int, Result<Int, TestError>> { state in
            let v = state
            state += 1
            return .success(v)
        }
        let result = s.statefulT.flatMap { value in
            StatefulTResult(Stateful<Int, Result<String, TestError>> { state in
                state += value
                return .success("\(value)")
            })
        }
        let (output, finalState) = result.rawValue.runStateful(5)
        #expect(output == .success("5"))
        #expect(finalState == 11) // 5+1=6, 6+5=11
    }

    @Test func flatMapFailure() {
        let s = Stateful<Int, Result<Int, TestError>>.pure(.failure(.failure))
        let result = s.statefulT.flatMap { value in
            StatefulTResult(Stateful<Int, Result<String, TestError>>.pure(.success("\(value)")))
        }
        #expect(result.rawValue.eval(0) == .failure(.failure))
    }

    // MARK: - Result<Stateful<S, A>, E> — Result as outer, Stateful as inner

    @Test func resultTStatefulMapTSuccess() {
        let r: Result<Stateful<Int, Int>, TestError> = .success(.get)
        let mapped = r.resultT.map { $0 * 3 }.rawValue
        #expect(mapped.map { $0.eval(4) } == .success(12))
    }

    @Test func resultTStatefulMapTFailure() {
        let r: Result<Stateful<Int, Int>, TestError> = .failure(.failure)
        let mapped: Result<Stateful<Int, Int>, TestError> = r.resultT.map { $0 * 3 }.rawValue
        if case let .failure(e) = mapped {
            #expect(e == .failure)
        } else {
            Issue.record("Expected .failure")
        }
    }
}
