import XCTest
@testable import Reader
@testable import ConcurrencyFP
@testable import ReaderConcurrencyFP
@testable import ReaderConcurrencyOperators
@testable import ConcurrencyOperators
@testable import Operators
import FP

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class ReaderConcurrencyOperatorsTests: XCTestCase {

    struct Environment {
        let multiplier: Int
    }

    // MARK: - Functor Operators

    func testFunctorOperatorFmap() async throws {
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

        XCTAssertEqual(results, [10, 20])
    }

    // MARK: - Monad Operators

    func testMonadOperatorBind() async throws {
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

        XCTAssertEqual(results, [10, 15])
    }

    func testMonadOperatorBindReverse() async throws {
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

        XCTAssertEqual(results, [10, 15])
    }

    // MARK: - Applicative Operators

    func testApplicativeOperatorSequenceRight() async throws {
        let readerA = Reader<Environment, AsyncStream<Int>> { env in
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
        XCTAssertEqual(results, [5, 10])
    }

    func testApplicativeOperatorSequenceLeft() async throws {
        let readerA = Reader<Environment, AsyncStream<Int>> { env in
            AsyncStream { continuation in
                continuation.yield(env.multiplier)
                continuation.yield(env.multiplier * 2)
                continuation.finish()
            }
        }

        let readerB = Reader<Environment, AsyncStream<Int>> { env in
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
        XCTAssertEqual(results, [5, 10])
    }
}
