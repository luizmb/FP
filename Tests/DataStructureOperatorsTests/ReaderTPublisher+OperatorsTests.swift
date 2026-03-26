import DataStructureOperators
import DataStructure
import Testing
import Combine
import CoreFP
import CoreFPOperators

@MainActor
@Suite struct ReaderCombineOperatorsTests {

    struct Environment {
        let multiplier: Int
    }

    enum TestError: Error {
        case test
    }

    // MARK: - Functor Operators

    @Test func functorOperatorFmap() {
        guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
        let reader = Reader<Environment, any Publisher<Int, TestError>> { env in
            Just(env.multiplier)
                .setFailureType(to: TestError.self)
                .eraseToAnyPublisher()
        }

        let mapped = { $0 * 2 } <£^> reader

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

    @Test func functorOperatorFlippedFmap() {
        guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
        let reader = Reader<Environment, any Publisher<Int, TestError>> { env in
            Just(env.multiplier)
                .setFailureType(to: TestError.self)
                .eraseToAnyPublisher()
        }

        let mapped = reader <&^> { $0 * 2 }

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

    // MARK: - Applicative Operators

    @Test func applicativeOperatorApply() {
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

        let result = readerFn <*> readerValue

        let env = Environment(multiplier: 5)
        var cancellables = Set<AnyCancellable>()
        var capturedValue: Int?

        result(env)
            .sink(
                receiveCompletion: ignore,
                receiveValue: { value in capturedValue = value }
            )
            .store(in: &cancellables)

        #expect(capturedValue == 15)
    }

    // MARK: - Monad Operators

    @Test func monadOperatorBind() {
        guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
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
        var capturedValue: String?

        bound(env)
            .sink(
                receiveCompletion: ignore,
                receiveValue: { value in capturedValue = value }
            )
            .store(in: &cancellables)

        #expect(capturedValue == "10")
    }

    @Test func monadOperatorFlippedBind() {
        guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
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
        var capturedValue: String?

        bound(env)
            .sink(
                receiveCompletion: ignore,
                receiveValue: { value in capturedValue = value }
            )
            .store(in: &cancellables)

        #expect(capturedValue == "10")
    }

    @Test func kleisliComposition() {
        guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
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
        var capturedValue: Int?

        pipeline("7")(env)
            .sink(
                receiveCompletion: ignore,
                receiveValue: { value in capturedValue = value }
            )
            .store(in: &cancellables)

        #expect(capturedValue == 21)
    }
}
