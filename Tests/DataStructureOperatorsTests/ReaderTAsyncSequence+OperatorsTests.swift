import DataStructureOperators
import DataStructure
import Testing
import Core
import CoreOperators

@Suite struct ReaderConcurrencyOperatorsTests {

    struct Environment {
        let multiplier: Int
    }

    // MARK: - Functor Operators

    @Test func functorOperatorFmap() async throws {
        let reader = Reader<Environment, AsyncStream<Int>> { env in
            AsyncStream { continuation in
                continuation.yield(env.multiplier)
                continuation.yield(env.multiplier * 2)
                continuation.finish()
            }
        }

        let mapped = { $0 * 2 } <£> reader

        let env = Environment(multiplier: 5)
        var results: [Int] = []

        for try await value in mapped(env) {
            results.append(value)
        }

        #expect(results == [10, 20])
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

        let bound = reader >>- { value in
            Reader<Environment, AsyncStream<Int>> { env in
                AsyncStream { continuation in
                    continuation.yield(value + env.multiplier)
                    continuation.finish()
                }
            }
        }

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

        let fn: @Sendable (Int) async throws -> Reader<Environment, AsyncStream<Int>> = { value in
            Reader<Environment, AsyncStream<Int>> { env in
                AsyncStream { continuation in
                    continuation.yield(value + env.multiplier)
                    continuation.finish()
                }
            }
        }

        let bound = fn -<< reader

        let env = Environment(multiplier: 5)
        var results: [Int] = []

        for try await value in bound(env) {
            results.append(value)
        }

        #expect(results == [10, 15])
    }

    // MARK: - Applicative Operators

    @Test func applicativeOperatorSequenceRight() async throws {
        let readerA = Reader<Environment, AsyncStream<Int>> { _ in
            AsyncStream { continuation in
                continuation.yield(1)
                continuation.yield(2)
                continuation.finish()
            }
        }

        let readerB = Reader<Environment, AsyncStream<Int>> { env in
            AsyncStream { continuation in
                continuation.yield(env.multiplier)
                continuation.yield(env.multiplier * 2)
                continuation.finish()
            }
        }

        let result = readerA *> readerB

        let env = Environment(multiplier: 5)
        var results: [Int] = []

        for try await value in result(env) {
            results.append(value)
        }

        // *> zips the streams (pairs elements 1:1) and keeps the right values
        #expect(results == [5, 10])
    }

    @Test func applicativeOperatorSequenceLeft() async throws {
        let readerA = Reader<Environment, AsyncStream<Int>> { env in
            AsyncStream { continuation in
                continuation.yield(env.multiplier)
                continuation.yield(env.multiplier * 2)
                continuation.finish()
            }
        }

        let readerB = Reader<Environment, AsyncStream<Int>> { _ in
            AsyncStream { continuation in
                continuation.yield(1)
                continuation.yield(2)
                continuation.finish()
            }
        }

        let result = readerA <* readerB

        let env = Environment(multiplier: 5)
        var results: [Int] = []

        for try await value in result(env) {
            results.append(value)
        }

        // <* zips the streams (pairs elements 1:1) and keeps the left values
        #expect(results == [5, 10])
    }
}
