// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct KleisliTStatefulTests {
    enum TestError: Error, Equatable { case failure }

    // MARK: - Stateful<S, Either<L, A>> — Stateful as outer, Either as inner

    @Test func statefulTEither() {
        let fn1: @Sendable (Int) -> Stateful<Int, Either<String, Int>> = { n in
            Stateful { state in
                state += 1
                return .right(n * 2)
            }
        }
        let fn2: @Sendable (Int) -> Stateful<Int, Either<String, String>> = { n in
            Stateful { state in
                state += 10
                return .right("\(n)")
            }
        }

        let (value, finalState) = kleisliT(fn1, fn2)(5).runStateful(0)
        #expect(value == .right("10"))
        #expect(finalState == 11)

        let failing: @Sendable (Int) -> Stateful<Int, Either<String, Int>> = const(
            Stateful { state in
                state += 1
                return .left("boom")
            }
        )
        let (leftValue, leftState) = kleisliT(failing, fn2)(5).runStateful(0)
        #expect(leftValue == .left("boom"))
        #expect(leftState == 1)
    }

    // MARK: - Stateful<S, A?> — Stateful as outer, Optional as inner

    @Test func statefulTOptional() {
        let fn1: @Sendable (Int) -> Stateful<Int, Int?> = { n in
            Stateful { state in
                state += 1
                return n * 2
            }
        }
        let fn2: @Sendable (Int) -> Stateful<Int, String?> = { n in
            Stateful { state in
                state += 10
                return "\(n)"
            }
        }

        let (value, finalState) = kleisliT(fn1, fn2)(5).runStateful(0)
        #expect(value == "10")
        #expect(finalState == 11)

        let none: @Sendable (Int) -> Stateful<Int, Int?> = const(
            Stateful { state in
                state += 1
                return nil
            }
        )
        let (nilValue, nilState) = kleisliT(none, fn2)(5).runStateful(0)
        #expect(nilValue == nil)
        #expect(nilState == 1)
    }

    // MARK: - Stateful<S, Result<A, E>> — Stateful as outer, Result as inner

    @Test func statefulTResult() {
        let fn1: @Sendable (Int) -> Stateful<Int, Result<Int, TestError>> = { n in
            Stateful { state in
                state += 1
                return .success(n * 2)
            }
        }
        let fn2: @Sendable (Int) -> Stateful<Int, Result<String, TestError>> = { n in
            Stateful { state in
                state += 10
                return .success("\(n)")
            }
        }

        let (value, finalState) = kleisliT(fn1, fn2)(5).runStateful(0)
        #expect(value == .success("10"))
        #expect(finalState == 11)

        let failing: @Sendable (Int) -> Stateful<Int, Result<Int, TestError>> = const(
            Stateful { state in
                state += 1
                return .failure(.failure)
            }
        )
        let (failureValue, failureState) = kleisliT(failing, fn2)(5).runStateful(0)
        #expect(failureValue == .failure(.failure))
        #expect(failureState == 1)
    }
}
