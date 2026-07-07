// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct KleisliTStatefulTests {
    enum TestError: Error, Equatable { case failure }

    // MARK: - [Stateful<S, A>] — Array as outer, Stateful as inner

    @Test func arrayTStateful() {
        let fn1: @Sendable (Int) -> [Stateful<Int, Int>] = { n in
            [
                Stateful { state in
                    state += 1
                    return n * 2
                }
            ]
        }
        let fn2: @Sendable (Int) -> Stateful<Int, String> = { n in
            Stateful { state in
                state += 10
                return "\(n)"
            }
        }

        let statefuls = kleisliT(fn1, fn2)(5)
        #expect(statefuls.count == 1)
        let (value, finalState) = statefuls[0].runStateful(0)
        #expect(value == "10")
        #expect(finalState == 11)

        let empty: @Sendable (Int) -> [Stateful<Int, Int>] = const([])
        #expect(kleisliT(empty, fn2)(5).isEmpty)
    }

    // MARK: - Stateful<S, A>? — Optional as outer, Stateful as inner

    @Test func optionalTStateful() {
        let fn1: @Sendable (Int) -> Stateful<Int, Int>? = { n in
            Stateful { state in
                state += 1
                return n * 2
            }
        }
        let fn2: @Sendable (Int) -> Stateful<Int, String> = { n in
            Stateful { state in
                state += 10
                return "\(n)"
            }
        }

        if let stateful = kleisliT(fn1, fn2)(5) {
            let (value, finalState) = stateful.runStateful(0)
            #expect(value == "10")
            #expect(finalState == 11)
        } else {
            Issue.record("Expected non-nil Stateful")
        }

        let none: @Sendable (Int) -> Stateful<Int, Int>? = const(nil)
        #expect(kleisliT(none, fn2)(5) == nil)
    }

    // MARK: - Result<Stateful<S, A>, E> — Result as outer, Stateful as inner

    @Test func resultTStateful() {
        let fn1: @Sendable (Int) -> Result<Stateful<Int, Int>, TestError> = { n in
            .success(
                Stateful { state in
                    state += 1
                    return n * 2
                }
            )
        }
        let fn2: @Sendable (Int) -> Stateful<Int, String> = { n in
            Stateful { state in
                state += 10
                return "\(n)"
            }
        }

        switch kleisliT(fn1, fn2)(5) {
        case let .success(stateful):
            let (value, finalState) = stateful.runStateful(0)
            #expect(value == "10")
            #expect(finalState == 11)

        case .failure:
            Issue.record("Expected .success")
        }

        let failing: @Sendable (Int) -> Result<Stateful<Int, Int>, TestError> = const(.failure(.failure))
        switch kleisliT(failing, fn2)(5) {
        case .success:
            Issue.record("Expected .failure")

        case let .failure(error):
            #expect(error == .failure)
        }
    }

    // MARK: - Stateful<S, [A]> — Stateful as outer, Array as inner

    @Test func statefulTArray() {
        let fn1: @Sendable (Int) -> Stateful<Int, [Int]> = { n in
            Stateful { state in
                state += 1
                return [n, n + 1]
            }
        }
        let fn2: @Sendable (Int) -> Stateful<Int, [String]> = { n in
            Stateful { state in
                state += n
                return ["\(n)"]
            }
        }

        let (value, finalState) = kleisliT(fn1, fn2)(5).runStateful(0)
        #expect(value == ["5", "6"])
        #expect(finalState == 12)

        let empty: @Sendable (Int) -> Stateful<Int, [Int]> = const(
            Stateful { state in
                state += 1
                return []
            }
        )
        let (emptyValue, emptyState) = kleisliT(empty, fn2)(5).runStateful(0)
        #expect(emptyValue.isEmpty)
        #expect(emptyState == 1)
    }

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
