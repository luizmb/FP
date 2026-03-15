import XCTest
@testable import Reader
import FP

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class ReaderConcurrencyFPTests: XCTestCase {

    struct Environment {
        let multiplier: Int
    }

    // MARK: - ReaderT + AsyncSequence Functor Tests

    func testMapT() async throws {
        let reader = Reader<Environment, AsyncStream<Int>> { env in
            AsyncStream { continuation in
                continuation.yield(env.multiplier)
                continuation.yield(env.multiplier * 2)
                continuation.finish()
            }
        }

        let mapped = reader.mapT { $0 * 2 }

        let env = Environment(multiplier: 5)
        var results: [Int] = []

        for try await value in mapped(env) {
            results.append(value)
        }

        XCTAssertEqual(results, [10, 20])
    }

    // MARK: - ReaderT + AsyncSequence Applicative Tests

    func testLiftA2ReaderAsyncStream() async throws {
        let readerA = Reader<Environment, AsyncStream<Int>> { env in
            AsyncStream { continuation in
                continuation.yield(env.multiplier)
                continuation.yield(env.multiplier * 2)
                continuation.finish()
            }
        }

        let readerB = Reader<Environment, AsyncStream<Int>> { _ in
            AsyncStream { continuation in
                continuation.yield(10)
                continuation.yield(20)
                continuation.finish()
            }
        }

        let combined = liftA2ReaderAsyncStream { a, b in a + b }(readerA, readerB)

        let env = Environment(multiplier: 3)
        var results: [Int] = []

        for try await value in combined(env) {
            results.append(value)
        }

        // zips element-by-element: (3+10, 6+20) = (13, 26)
        XCTAssertEqual(results, [13, 26])
    }

    // MARK: - ReaderT + AsyncSequence Monad Tests

    func testFlatMapT() async throws {
        let reader = Reader<Environment, AsyncStream<Int>> { env in
            AsyncStream { continuation in
                continuation.yield(env.multiplier)
                continuation.finish()
            }
        }

        let bound = reader.flatMapT { value in
            Reader<Environment, AsyncStream<String>> { env in
                AsyncStream { continuation in
                    continuation.yield("\(value * env.multiplier)")
                    continuation.finish()
                }
            }
        }

        let env = Environment(multiplier: 4)
        var results: [String] = []

        for try await value in bound(env) {
            results.append(value)
        }

        XCTAssertEqual(results, ["16"])
    }
}
