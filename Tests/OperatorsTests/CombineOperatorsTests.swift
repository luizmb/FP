import XCTest
import Combine
@testable import FP
@testable import Operators
import Operators
import FP

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
final class PublisherTests: XCTestCase {
    nonisolated(unsafe) var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    // MARK: - Functor Tests

    func testFmap() {
        let expectation = expectation(description: "fmap completes")
        let publisher = [1, 2, 3].publisher

        let doubled = Result<Int, Never>.Publisher.fmap { $0 * 2 }(publisher)

        var results: [Int] = []
        doubled.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, [2, 4, 6])
    }

    func testFunctorIdentityLaw() {
        let expectation = expectation(description: "identity law")
        let publisher = [1, 2, 3].publisher

        let identity: (Int) -> Int = { $0 }
        let mapped = Result<Int, Never>.Publisher.fmap(identity)(publisher)

        var originalResults: [Int] = []
        var mappedResults: [Int] = []

        publisher.sink(
            receiveCompletion: { _ in },
            receiveValue: { originalResults.append($0) }
        ).store(in: &cancellables)

        mapped.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { mappedResults.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(originalResults, mappedResults)
    }

    func testFunctorCompositionLaw() {
        let expectation = expectation(description: "composition law")
        let publisher = [1, 2, 3].publisher

        let f: (Int) -> Int = { $0 * 2 }
        let g: (Int) -> String = { "\($0)" }

        // fmap (g . f) == fmap g . fmap f
        let composed = (compose(f, g) <£> publisher)
        let separate = (g <£> (f <£> publisher))

        var composedResults: [String] = []
        var separateResults: [String] = []

        composed.sink(
            receiveCompletion: { _ in },
            receiveValue: { composedResults.append($0) }
        ).store(in: &cancellables)

        separate.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { separateResults.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(composedResults, separateResults)
    }

    func testFunctorOperators() {
        let expectation = expectation(description: "functor operators")
        let publisher = [1, 2, 3].publisher

        // Test <£> operator
        let doubled = { $0 * 2 } <£> publisher

        var results: [Int] = []
        doubled.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, [2, 4, 6])
    }

    func testMapReplace() {
        let expectation = expectation(description: "map replace")
        let publisher = [1, 2, 3].publisher

        // Test £> operator
        let replaced = publisher £> 99

        var results: [Int] = []
        replaced.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, [99, 99, 99])
    }

    func testMapReplaceFlipped() {
        let expectation = expectation(description: "map replace flipped")
        let publisher = [1, 2, 3].publisher

        // Test <£ operator
        let replaced = 42 <£ publisher

        var results: [Int] = []
        replaced.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, [42, 42, 42])
    }

    // MARK: - Bimap Tests

    func testMapLeft() {
        let expectation = expectation(description: "mapLeft")
        let publisher = [1, 2, 3].publisher

        let doubled = publisher.mapLeft { $0 * 2 }

        var results: [Int] = []
        doubled.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, [2, 4, 6])
    }

    func testMapRight() {
        enum TestError: Error {
            case original
            case mapped
        }

        let expectation = expectation(description: "mapRight")
        let publisher = Fail<Int, TestError>(error: .original)

        let mapped = publisher.mapRight { _ in TestError.mapped }

        mapped.sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTAssertEqual(error, .mapped)
                }
                expectation.fulfill()
            },
            receiveValue: { _ in }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    func testBimap() {
        enum TestError: Error {
            case original
            case mapped
        }

        let expectation1 = expectation(description: "bimap success")
        let expectation2 = expectation(description: "bimap failure")

        let successPublisher = [1, 2, 3].publisher.setFailureType(to: TestError.self)
        let failurePublisher = Fail<Int, TestError>(error: .original)

        let bimappedSuccess = successPublisher.bimap({ $0 * 2 }, { _ in TestError.mapped })
        let bimappedFailure = failurePublisher.bimap({ $0 * 2 }, { _ in TestError.mapped })

        var results: [Int] = []
        bimappedSuccess.sink(
            receiveCompletion: { _ in expectation1.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        bimappedFailure.sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTAssertEqual(error, .mapped)
                }
                expectation2.fulfill()
            },
            receiveValue: { _ in }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, [2, 4, 6])
    }

    // MARK: - Applicative Tests

    func testLiftA2() {
        let expectation = expectation(description: "liftA2")
        let publisher1 = [1, 2].publisher
        let publisher2 = [10, 20].publisher

        let add: (Int, Int) -> Int = { $0 + $1 }
        let lifted = Result<Int, Never>.Publisher.liftA2(add)
        let result = lifted(publisher1, publisher2)

        var results: [Int] = []
        result.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, [11, 22])
    }

    func testZip() {
        let expectation = expectation(description: "zip")
        let publisher1 = [1, 2, 3].publisher
        let publisher2 = ["a", "b", "c"].publisher

        let zipped = Result<(Int, String), Never>.Publisher.zip(publisher1, publisher2)

        var results: [(Int, String)] = []
        zipped.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].0, 1)
        XCTAssertEqual(results[0].1, "a")
        XCTAssertEqual(results[1].0, 2)
        XCTAssertEqual(results[1].1, "b")
        XCTAssertEqual(results[2].0, 3)
        XCTAssertEqual(results[2].1, "c")
    }

    func testApplyOperator() {
        let expectation = expectation(description: "apply operator")

        let functions = [{ (x: Int) in x * 2 }, { (x: Int) in x + 10 }].publisher
        let values = [5, 3].publisher

        let applied = functions <*> values

        var results: [Int] = []
        applied.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, [10, 13])
    }

    func testSequenceRight() {
        let expectation = expectation(description: "sequence right")
        let publisher1 = [1, 2].publisher
        let publisher2 = [10, 20].publisher

        let result = publisher1 *> publisher2

        var results: [Int] = []
        result.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, [10, 20])
    }

    func testSequenceLeft() {
        let expectation = expectation(description: "sequence left")
        let publisher1 = [1, 2].publisher
        let publisher2 = [10, 20].publisher

        let result = publisher1 <* publisher2

        var results: [Int] = []
        result.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, [1, 2])
    }

    // MARK: - Monad Tests

    func testBind() {
        let expectation = expectation(description: "bind")
        let publisher = [1, 2].publisher

        let fn: (Int) -> AnyPublisher<Int, Never> = { value in
            [value, value * 10].publisher.eraseToAnyPublisher()
        }

        let bound = Result<Int, Never>.Publisher.bind(fn)(publisher)

        var results: [Int] = []
        bound.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, [1, 10, 2, 20])
    }

    func testBindOperator() {
        let expectation = expectation(description: "bind operator")
        let publisher = [1, 2].publisher

        let result = publisher >>- { value in
            [value * 2].publisher
        }

        var results: [Int] = []
        result.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, [2, 4])
    }

    func testFlippedBindOperator() {
        let expectation = expectation(description: "flipped bind")
        let publisher = [1, 2].publisher

        let fn: (Int) -> AnyPublisher<Int, Never> = { value in
            [value * 3].publisher.eraseToAnyPublisher()
        }

        let result = fn -<< publisher

        var results: [Int] = []
        result.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, [3, 6])
    }

    func testKleisliComposition() {
        let expectation = expectation(description: "kleisli composition")

        let fn1: (Int) -> AnyPublisher<Int, Never> = { [$0 * 2].publisher.eraseToAnyPublisher() }
        let fn2: (Int) -> AnyPublisher<String, Never> = { ["\($0)"].publisher.eraseToAnyPublisher() }

        let composed = AnyPublisher<Int, Never>.kleisli(fn1, fn2)
        let result = composed(5)

        var results: [String] = []
        result.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, ["10"])
    }

    func testKleisliOperator() {
        let expectation = expectation(description: "kleisli operator")

        let fn1: (Int) -> AnyPublisher<Int, Never> = { [$0 * 2].publisher.eraseToAnyPublisher() }
        let fn2: (Int) -> AnyPublisher<String, Never> = { ["\($0)"].publisher.eraseToAnyPublisher() }

        let composed = fn1 >=> fn2
        let result = composed(5)

        var results: [String] = []
        result.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, ["10"])
    }

    func testFlippedFmapOperator() {
        let expectation = expectation(description: "flipped fmap")
        let publisher = [1, 2, 3].publisher

        let result = publisher <&> { $0 * 2 }

        var results: [Int] = []
        result.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { results.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(results, [2, 4, 6])
    }

    func testMonadLeftIdentity() {
        let expectation = expectation(description: "monad left identity")
        let value = 5

        let f: (Int) -> AnyPublisher<Int, Never> = { [$0 * 2].publisher.eraseToAnyPublisher() }

        // return a >>= f == f a
        let left = Just(value).eraseToAnyPublisher() >>- f
        let right = f(value)

        var leftResults: [Int] = []
        var rightResults: [Int] = []

        left.sink(
            receiveCompletion: { _ in },
            receiveValue: { leftResults.append($0) }
        ).store(in: &cancellables)

        right.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { rightResults.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(leftResults, rightResults)
    }

    func testMonadRightIdentity() {
        let expectation = expectation(description: "monad right identity")
        let publisher = [1, 2, 3].publisher.eraseToAnyPublisher()

        // m >>= return == m
        let bound = publisher >>- { Just($0).eraseToAnyPublisher() }

        var originalResults: [Int] = []
        var boundResults: [Int] = []

        publisher.sink(
            receiveCompletion: { _ in },
            receiveValue: { originalResults.append($0) }
        ).store(in: &cancellables)

        bound.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { boundResults.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(originalResults, boundResults)
    }

    func testMonadAssociativity() {
        let expectation = expectation(description: "monad associativity")
        let publisher = [1].publisher

        let f: (Int) -> AnyPublisher<Int, Never> = { [$0 * 2].publisher.eraseToAnyPublisher() }
        let g: (Int) -> AnyPublisher<Int, Never> = { [$0 + 10].publisher.eraseToAnyPublisher() }

        // (m >>= f) >>= g == m >>= (\x -> f x >>= g)
        let left = (publisher >>- f) >>- g
        let right = publisher >>- { x in
            f(x).eraseToAnyPublisher().flatMap(g).eraseToAnyPublisher()
        }

        var leftResults: [Int] = []
        var rightResults: [Int] = []

        left.sink(
            receiveCompletion: { _ in },
            receiveValue: { leftResults.append($0) }
        ).store(in: &cancellables)

        right.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { rightResults.append($0) }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 1)
        XCTAssertEqual(leftResults, rightResults)
    }
}
