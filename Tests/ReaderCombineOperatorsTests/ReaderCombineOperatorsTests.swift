import XCTest
import Combine
@testable import Reader
@testable import FP
@testable import ReaderCombineFP
@testable import ReaderCombineOperators
@testable import Operators
@testable import Operators
import FP

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
@MainActor
final class ReaderCombineOperatorsTests: XCTestCase {

    struct Environment {
        let multiplier: Int
    }

    enum TestError: Error {
        case test
    }

    // MARK: - Functor Operators

    func testFunctorOperatorFmap() {
        let expectation = expectation(description: "Publisher completes")
        let reader = Reader<Environment, any Publisher<Int, TestError>> { env in
            Just(env.multiplier)
                .setFailureType(to: TestError.self)
                .eraseToAnyPublisher()
        }

        let mapped = { $0 * 2 } <£> reader

        let env = Environment(multiplier: 5)
        var cancellables = Set<AnyCancellable>()

        mapped(env)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { value in XCTAssertEqual(value, 10) }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Applicative Operators

    func testApplicativeOperatorApply() {
        let expectation = expectation(description: "Publisher completes")
        let readerFn = Reader<Environment, any Publisher<(Int) -> Int, TestError>> { env in
            Just({ $0 + env.multiplier })
                .setFailureType(to: TestError.self)
                .eraseToAnyPublisher()
        }

        let readerValue = Reader<Environment, any Publisher<Int, TestError>> { _ in
            Just(10)
                .setFailureType(to: TestError.self)
                .eraseToAnyPublisher()
        }

        let result = readerFn <*> readerValue

        let env = Environment(multiplier: 5)
        var cancellables = Set<AnyCancellable>()

        result(env)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { value in XCTAssertEqual(value, 15) }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }
}
