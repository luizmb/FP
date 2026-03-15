import XCTest
import Combine
@testable import FP
import FP

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
final class PublisherTests: XCTestCase {

    enum TestError: Error, Equatable {
        case test
    }

    // MARK: - Functor Tests (Core Methods)

    func testMapLeft() {
        let expectation = self.expectation(description: "Publisher mapLeft")
        var results: [Int] = []

        let publisher = [1, 2, 3].publisher
        let mapped = publisher.mapLeft { $0 * 2 }

        mapped.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(results, [2, 4, 6])
    }

    func testCurriedFmap() {
        let expectation = self.expectation(description: "Publisher curried fmap")
        var results: [String] = []

        let publisher = [1, 2, 3].publisher
        let toString = AnyPublisher<Int, Never>.fmap { "\($0)" }
        let mapped = toString(publisher)

        mapped.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(results, ["1", "2", "3"])
    }

    // MARK: - Applicative Tests (Core Methods)

    func testLiftA2() {
        let expectation = self.expectation(description: "Publisher liftA2")
        var results: [Int] = []

        let publisher1 = [1, 2].publisher
        let publisher2 = [10, 20].publisher

        let add: (Int, Int) -> Int = { $0 + $1 }
        let combined = AnyPublisher<Int, Never>.liftA2(add)(publisher1, publisher2)

        combined.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
        // zip pairs elements, not cartesian product
        XCTAssertEqual(results, [11, 22])
    }

    // MARK: - Monad Tests (Core Methods)

    func testBind() {
        let expectation = self.expectation(description: "Publisher bind")
        var results: [Int] = []

        let publisher = [1, 2].publisher
        let fn: (Int) -> AnyPublisher<Int, Never> = { value in
            [value, value * 10].publisher.eraseToAnyPublisher()
        }
        let bound = AnyPublisher<Int, Never>.bind(fn)(publisher)

        bound.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(results, [1, 10, 2, 20])
    }

    func testKleisli() {
        let expectation = self.expectation(description: "Publisher kleisli")
        var results: [String] = []

        let f: (Int) -> AnyPublisher<Int, Never> = { value in
            Just(value * 2).eraseToAnyPublisher()
        }

        let g: (Int) -> AnyPublisher<String, Never> = { value in
            Just("\(value)").eraseToAnyPublisher()
        }

        let composed = AnyPublisher<Int, Never>.kleisli(f, g)
        let result = composed(5)

        result.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(results, ["10"])
    }

    // MARK: - Helper

    private var cancellables = Set<AnyCancellable>()
}
