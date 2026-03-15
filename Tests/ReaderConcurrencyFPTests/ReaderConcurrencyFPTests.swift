import XCTest
@testable import Reader
@testable import FP
@testable import ReaderConcurrencyFP
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
}
