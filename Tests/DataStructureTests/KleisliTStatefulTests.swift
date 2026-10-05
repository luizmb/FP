// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct KleisliTStatefulTests {
    enum TestError: Error, Equatable { case failure }

    // MARK: - StatefulTEither — Stateful as outer, Either as inner

    @Test func statefulTEither() {
        let fn1: @Sendable (Int) -> StatefulTEither<Int, String, Int> = { n in
            StatefulTEither(Stateful { state in
                state += 1
                return .right(n * 2)
            })
        }
        let fn2: @Sendable (Int) -> StatefulTEither<Int, String, String> = { n in
            StatefulTEither(Stateful { state in
                state += 10
                return .right("\(n)")
            })
        }

        let (value, finalState) = StatefulTEither.kleisli(fn1, fn2)(5).rawValue.runStateful(0)
        #expect(value == .right("10"))
        #expect(finalState == 11)

        let failing: @Sendable (Int) -> StatefulTEither<Int, String, Int> = const(
            StatefulTEither(Stateful { state in
                state += 1
                return .left("boom")
            })
        )
        let (leftValue, leftState) = StatefulTEither.kleisli(failing, fn2)(5).rawValue.runStateful(0)
        #expect(leftValue == .left("boom"))
        #expect(leftState == 1)
    }

    // MARK: - StatefulTOptional — Stateful as outer, Optional as inner

    @Test func statefulTOptional() {
        let fn1: @Sendable (Int) -> StatefulTOptional<Int, Int> = { n in
            StatefulTOptional(Stateful { state in
                state += 1
                return n * 2
            })
        }
        let fn2: @Sendable (Int) -> StatefulTOptional<Int, String> = { n in
            StatefulTOptional(Stateful { state in
                state += 10
                return "\(n)"
            })
        }

        let (value, finalState) = StatefulTOptional.kleisli(fn1, fn2)(5).rawValue.runStateful(0)
        #expect(value == "10")
        #expect(finalState == 11)

        let none: @Sendable (Int) -> StatefulTOptional<Int, Int> = const(
            StatefulTOptional(Stateful { state in
                state += 1
                return nil
            })
        )
        let (nilValue, nilState) = StatefulTOptional.kleisli(none, fn2)(5).rawValue.runStateful(0)
        #expect(nilValue == nil)
        #expect(nilState == 1)
    }

    // MARK: - StatefulTResult — Stateful as outer, Result as inner

    @Test func statefulTResult() {
        let fn1: @Sendable (Int) -> StatefulTResult<Int, TestError, Int> = { n in
            StatefulTResult(Stateful { state in
                state += 1
                return .success(n * 2)
            })
        }
        let fn2: @Sendable (Int) -> StatefulTResult<Int, TestError, String> = { n in
            StatefulTResult(Stateful { state in
                state += 10
                return .success("\(n)")
            })
        }

        let (value, finalState) = StatefulTResult.kleisli(fn1, fn2)(5).rawValue.runStateful(0)
        #expect(value == .success("10"))
        #expect(finalState == 11)

        let failing: @Sendable (Int) -> StatefulTResult<Int, TestError, Int> = const(
            StatefulTResult(Stateful { state in
                state += 1
                return .failure(.failure)
            })
        )
        let (failureValue, failureState) = StatefulTResult.kleisli(failing, fn2)(5).rawValue.runStateful(0)
        #expect(failureValue == .failure(.failure))
        #expect(failureState == 1)
    }
}
