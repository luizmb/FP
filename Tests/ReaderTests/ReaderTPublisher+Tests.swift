import Testing
import Combine
@testable import Reader
import FP

@MainActor
@Suite struct ReaderCombineFPTests {

    struct Environment {
        let multiplier: Int
    }

    enum TestError: Error {
        case test
    }

    // MARK: - ReaderT + Publisher Functor Tests

    @Test func mapT() {
        guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
        let reader = Reader<Environment, any Publisher<Int, TestError>> { env in
            Just(env.multiplier)
                .setFailureType(to: TestError.self)
                .eraseToAnyPublisher()
        }

        let mapped = reader.mapT { $0 * 2 }

        let env = Environment(multiplier: 5)
        var cancellables = Set<AnyCancellable>()
        var capturedValue: Int?

        mapped(env)
            .sink(
                receiveCompletion: ignore,
                receiveValue: { value in capturedValue = value }
            )
            .store(in: &cancellables)

        #expect(capturedValue == 10)
    }

    // MARK: - ReaderT + Publisher Applicative Tests

    @Test func apply() {
        guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
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
        var capturedValue: Int?

        result(env)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { value in capturedValue = value }
            )
            .store(in: &cancellables)

        #expect(capturedValue == 15)
    }

    // MARK: - ReaderT + Publisher Monad Tests

    @Test func flatMapT() {
        guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
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
        var capturedValue: String?

        bound(env)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { value in capturedValue = value }
            )
            .store(in: &cancellables)

        #expect(capturedValue == "10")
    }
}
