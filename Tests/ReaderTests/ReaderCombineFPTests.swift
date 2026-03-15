import XCTest
import Combine
@testable import Reader
import FP

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
@MainActor
final class ReaderCombineFPTests: XCTestCase {

    struct Environment {
        let multiplier: Int
    }

    enum TestError: Error {
        case test
    }

    // MARK: - ReaderT + Publisher Functor Tests

    func testMapT() {
        let expectation = expectation(description: "Publisher completes")
        let reader = Reader<Environment, any Publisher<Int, TestError>> { env in
            Just(env.multiplier)
                .setFailureType(to: TestError.self)
                .eraseToAnyPublisher()
        }

        let mapped = reader.mapT { $0 * 2 }

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

    // MARK: - ReaderT + Publisher Applicative Tests

    func testApplyReaderPublisher() {
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

        let result = applyReaderPublisher(readerFn, readerValue)

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

    // MARK: - ReaderT + Publisher Monad Tests

    func testFlatMapT() {
        let expectation = expectation(description: "Publisher completes")
        let reader = Reader<Environment, any Publisher<Int, TestError>> { env in
            Just(env.multiplier)
                .setFailureType(to: TestError.self)
                .eraseToAnyPublisher()
        }

        let bound = reader.flatMapT { value in
            Reader<Environment, any Publisher<String, TestError>> { env in
                Just("\(value + env.multiplier)")
                    .setFailureType(to: TestError.self)
                    .eraseToAnyPublisher()
            }
        }

        let env = Environment(multiplier: 5)
        var cancellables = Set<AnyCancellable>()

        bound(env)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { value in XCTAssertEqual(value, "10") }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }
}
