import XCTest
import Combine
@testable import Reader
import FP
@testable import ReaderOperators
import Operators

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

    // MARK: - Monad Operators

    func testMonadOperatorBind() {
        let expectation = expectation(description: "Publisher completes")
        let reader = Reader<Environment, any Publisher<Int, TestError>> { env in
            Just(env.multiplier)
                .setFailureType(to: TestError.self)
                .eraseToAnyPublisher()
        }

        let bound = reader >>- { value in
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

    func testMonadOperatorFlippedBind() {
        let expectation = expectation(description: "Publisher completes")
        let reader = Reader<Environment, any Publisher<Int, TestError>> { env in
            Just(env.multiplier)
                .setFailureType(to: TestError.self)
                .eraseToAnyPublisher()
        }

        let fn: (Int) -> Reader<Environment, any Publisher<String, TestError>> = { value in
            Reader { env in
                Just("\(value + env.multiplier)")
                    .setFailureType(to: TestError.self)
                    .eraseToAnyPublisher()
            }
        }

        let bound = fn -<< reader

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

    func testKleisliComposition() {
        let expectation = expectation(description: "Publisher completes")

        let parse: (String) -> Reader<Environment, any Publisher<Int, TestError>> = { s in
            Reader { _ in
                Just(Int(s) ?? 0)
                    .setFailureType(to: TestError.self)
                    .eraseToAnyPublisher()
            }
        }

        let scale: (Int) -> Reader<Environment, any Publisher<Int, TestError>> = { n in
            Reader { env in
                Just(n * env.multiplier)
                    .setFailureType(to: TestError.self)
                    .eraseToAnyPublisher()
            }
        }

        let pipeline = parse >=> scale

        let env = Environment(multiplier: 3)
        var cancellables = Set<AnyCancellable>()

        pipeline("7")(env)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { value in XCTAssertEqual(value, 21) }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }
}
