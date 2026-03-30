import Combine
@testable import CoreFP
import Foundation
import Testing

@MainActor
@Suite struct PublisherTests {
    enum TestError: Error, Equatable {
        case test
    }

    // MARK: - Functor Tests (Core Methods)

    @Test func mapLeft() {
        var results: [Int] = []
        var cancellables = Set<AnyCancellable>()

        let publisher = [1, 2, 3].publisher
        let mapped = publisher.mapLeft { $0 * 2 }

        mapped.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [2, 4, 6])
    }

    @Test func curriedFmap() {
        var results: [String] = []
        var cancellables = Set<AnyCancellable>()

        let publisher = [1, 2, 3].publisher
        let toString = AnyPublisher<Int, Never>.fmap { "\($0)" }
        let mapped = toString(publisher)

        mapped.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == ["1", "2", "3"])
    }

    // MARK: - Applicative Tests (Core Methods)

    @Test func basicLiftA2() {
        var results: [Int] = []
        var cancellables = Set<AnyCancellable>()

        let publisher1 = [1, 2].publisher
        let publisher2 = [10, 20].publisher

        let add: (Int, Int) -> Int = { $0 + $1 }
        let combined = AnyPublisher<Int, Never>.liftA2(add)(publisher1, publisher2)

        combined.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        // zip pairs elements, not cartesian product
        #expect(results == [11, 22])
    }

    // MARK: - Monad Tests (Core Methods)

    @Test func bind() {
        var results: [Int] = []
        var cancellables = Set<AnyCancellable>()

        let publisher = [1, 2].publisher
        let fn: (Int) -> AnyPublisher<Int, Never> = { value in
            [value, value * 10].publisher.eraseToAnyPublisher()
        }
        let bound = AnyPublisher<Int, Never>.bind(fn)(publisher)

        bound.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [1, 10, 2, 20])
    }

    @Test func kleisli() {
        var results: [String] = []
        var cancellables = Set<AnyCancellable>()

        let f: (Int) -> AnyPublisher<Int, Never> = { value in
            Just(value * 2).eraseToAnyPublisher()
        }

        let g: (Int) -> AnyPublisher<String, Never> = { value in
            Just("\(value)").eraseToAnyPublisher()
        }

        let composed = AnyPublisher<Int, Never>.kleisli(f, g)
        let result = composed(5)

        result.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == ["10"])
    }

    // MARK: - Alternative

    @Test func altSuccessPublisherPassesThrough() {
        var results: [Int] = []
        var cancellables = Set<AnyCancellable>()

        let lhs: any Publisher<Int, TestError> = [1, 2, 3].publisher.setFailureType(to: TestError.self).eraseToAnyPublisher()
        let rhs: any Publisher<Int, TestError> = [4, 5, 6].publisher.setFailureType(to: TestError.self).eraseToAnyPublisher()

        altPublisher(lhs, rhs)
            .sink(receiveCompletion: ignore, receiveValue: { results.append($0) })
            .store(in: &cancellables)

        #expect(results == [1, 2, 3])
    }

    @Test func altFailingPublisherFallsBackToRhs() {
        var results: [Int] = []
        var cancellables = Set<AnyCancellable>()

        let lhs: any Publisher<Int, TestError> = Fail(error: TestError.test).eraseToAnyPublisher()
        let rhs: any Publisher<Int, TestError> = [42].publisher.setFailureType(to: TestError.self).eraseToAnyPublisher()

        altPublisher(lhs, rhs)
            .sink(receiveCompletion: ignore, receiveValue: { results.append($0) })
            .store(in: &cancellables)

        #expect(results == [42])
    }
}
