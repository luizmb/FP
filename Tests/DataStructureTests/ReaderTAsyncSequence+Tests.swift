// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct ReaderConcurrencyFPTests {
    struct Environment {
        let multiplier: Int
    }

    // MARK: - ReaderT + AsyncSequence Functor Tests

    @Test func map() async throws {
        let reader = Reader<Environment, AsyncStream<Int>> { env in
            AsyncStream { continuation in
                continuation.yield(env.multiplier)
                continuation.yield(env.multiplier * 2)
                continuation.finish()
            }
        }

        let mapped = reader.readerT.map { $0 * 2 }.rawValue

        let env = Environment(multiplier: 5)
        var results: [Int] = []

        for try await value in mapped(env) {
            results.append(value)
        }

        #expect(results == [10, 20])
    }

    // MARK: - ReaderT + AsyncSequence Applicative Tests

    @Test func liftA2() async throws {
        let readerA = Reader<Environment, AsyncStream<Int>> { env in
            AsyncStream { continuation in
                continuation.yield(env.multiplier)
                continuation.yield(env.multiplier * 2)
                continuation.finish()
            }
        }

        let fixedStream = AsyncStream<Int> { continuation in
            continuation.yield(10)
            continuation.yield(20)
            continuation.finish()
        }
        let readerB = Reader<Environment, AsyncStream<Int>>(const(fixedStream))

        let combined = ReaderTAsyncStream<Environment, Int>.liftA2 { a, b in a + b }(readerA.readerT, readerB.readerT).rawValue

        let env = Environment(multiplier: 3)
        var results: [Int] = []

        for try await value in combined(env) {
            results.append(value)
        }

        // bind-derived (concat): each left value over the whole right stream
        #expect(results == [13, 23, 16, 26])
    }

    // MARK: - ReaderT + AsyncSequence Monad Tests

    @Test func flatMap() async throws {
        let reader = Reader<Environment, AsyncStream<Int>> { env in
            AsyncStream { continuation in
                continuation.yield(env.multiplier)
                continuation.finish()
            }
        }

        let bound = reader.readerT.flatMap { value in
            ReaderTAsyncStream<Environment, String>(Reader { env in
                AsyncStream { continuation in
                    continuation.yield("\(value * env.multiplier)")
                    continuation.finish()
                }
            })
        }.rawValue

        let env = Environment(multiplier: 4)
        var results: [String] = []

        for try await value in bound(env) {
            results.append(value)
        }

        #expect(results == ["16"])
    }
}
