// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct StatefulTResultTests {
    enum TestError: Error, Equatable { case failure }

    // MARK: - Stateful<S, Result<A, E>> — State as outer, Result as inner

    @Test func mapTSuccess() {
        let s = Stateful<Int, Result<Int, TestError>>.pure(.success(5))
        let mapped = s.mapT { $0 * 2 }
        #expect(mapped.eval(0) == .success(10))
    }

    @Test func mapTFailure() {
        let s = Stateful<Int, Result<Int, TestError>>.pure(.failure(.failure))
        let mapped = s.mapT { $0 * 2 }
        #expect(mapped.eval(0) == .failure(.failure))
    }

    @Test func flatMapTSuccess() {
        let s = Stateful<Int, Result<Int, TestError>> { state in
            let v = state
            state += 1
            return .success(v)
        }
        let result = s.flatMapT { value in
            Stateful<Int, Result<String, TestError>> { state in
                state += value
                return .success("\(value)")
            }
        }
        let (output, finalState) = result.runStateful(5)
        #expect(output == .success("5"))
        #expect(finalState == 11) // 5+1=6, 6+5=11
    }

    @Test func flatMapTFailure() {
        let s = Stateful<Int, Result<Int, TestError>>.pure(.failure(.failure))
        let result = s.flatMapT { value in
            Stateful<Int, Result<String, TestError>>.pure(.success("\(value)"))
        }
        #expect(result.eval(0) == .failure(.failure))
    }

    // MARK: - Result<Stateful<S, A>, E> — Result as outer, Stateful as inner

    @Test func resultTStatefulMapTSuccess() {
        let r: Result<Stateful<Int, Int>, TestError> = .success(.get)
        let mapped = r.mapT { $0 * 3 }
        #expect(mapped.map { $0.eval(4) } == .success(12))
    }

    @Test func resultTStatefulMapTFailure() {
        let r: Result<Stateful<Int, Int>, TestError> = .failure(.failure)
        let mapped: Result<Stateful<Int, Int>, TestError> = r.mapT { $0 * 3 }
        if case .failure(let e) = mapped {
            #expect(e == .failure)
        } else {
            Issue.record("Expected .failure")
        }
    }

    @Test func resultTStatefulFlatMapTSuccess() {
        let r: Result<Stateful<Int, Int>, TestError> = .success(.get)
        let result = r.flatMapT { value in
            Stateful<Int, String>.pure("\(value)")
        }
        #expect(result.map { $0.eval(7) } == .success("7"))
    }

    @Test func resultTStatefulFlatMapTFailure() {
        let r: Result<Stateful<Int, Int>, TestError> = .failure(.failure)
        let result: Result<Stateful<Int, String>, TestError> = r.flatMapT { value in
            Stateful<Int, String>.pure("\(value)")
        }
        if case .failure(let e) = result {
            #expect(e == .failure)
        } else {
            Issue.record("Expected .failure")
        }
    }
}
