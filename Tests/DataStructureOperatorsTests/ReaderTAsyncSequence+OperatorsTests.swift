// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ReaderConcurrencyOperatorsTests {
    struct Environment {
        let multiplier: Int
    }

    // MARK: - Monad Operators

    @Test func monadOperatorBind() async throws {
        let reader = Reader<Environment, AsyncStream<Int>> { env in
            AsyncStream { continuation in
                continuation.yield(env.multiplier)
                continuation.yield(env.multiplier * 2)
                continuation.finish()
            }
        }

        let bound = (reader.readerT >>- { value in
            Reader<Environment, AsyncStream<Int>> { env in
                AsyncStream { continuation in
                    continuation.yield(value + env.multiplier)
                    continuation.finish()
                }
            }.readerT
        }).rawValue

        let env = Environment(multiplier: 5)
        var results: [Int] = []

        for try await value in bound(env) {
            results.append(value)
        }

        #expect(results == [10, 15])
    }

    @Test func monadOperatorBindReverse() async throws {
        let reader = Reader<Environment, AsyncStream<Int>> { env in
            AsyncStream { continuation in
                continuation.yield(env.multiplier)
                continuation.yield(env.multiplier * 2)
                continuation.finish()
            }
        }

        let fn: @Sendable (Int) -> ReaderTAsyncStream<Environment, Int> = { value in
            Reader<Environment, AsyncStream<Int>> { env in
                AsyncStream { continuation in
                    continuation.yield(value + env.multiplier)
                    continuation.finish()
                }
            }.readerT
        }

        let bound = (fn -<< reader.readerT).rawValue

        let env = Environment(multiplier: 5)
        var results: [Int] = []

        for try await value in bound(env) {
            results.append(value)
        }

        #expect(results == [10, 15])
    }

    // MARK: - Applicative Operators

    @Test func applicativeOperatorSequenceRight() async throws {
        let streamA = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }
        let readerA = Reader<Environment, AsyncStream<Int>>(const(streamA))

        let readerB = Reader<Environment, AsyncStream<Int>> { env in
            AsyncStream { continuation in
                continuation.yield(env.multiplier)
                continuation.yield(env.multiplier * 2)
                continuation.finish()
            }
        }

        let result = (readerA.readerT *> readerB.readerT).rawValue

        let env = Environment(multiplier: 5)
        var results: [Int] = []

        for try await value in result(env) {
            results.append(value)
        }

        // *> is bind-derived (concat): the whole right stream once per left value
        #expect(results == [5, 10, 5, 10])
    }

    @Test func applicativeOperatorSequenceLeft() async throws {
        let readerA = Reader<Environment, AsyncStream<Int>> { env in
            AsyncStream { continuation in
                continuation.yield(env.multiplier)
                continuation.yield(env.multiplier * 2)
                continuation.finish()
            }
        }

        let streamB = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }
        let readerB = Reader<Environment, AsyncStream<Int>>(const(streamB))

        let result = (readerA.readerT <* readerB.readerT).rawValue

        let env = Environment(multiplier: 5)
        var results: [Int] = []

        for try await value in result(env) {
            results.append(value)
        }

        // <* is bind-derived (concat): each left value once per right value
        #expect(results == [5, 5, 10, 10])
    }
}
