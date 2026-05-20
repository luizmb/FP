#if canImport(Combine)
import Combine
@testable import CoreFP
@testable import CoreFPOperators
import Testing
@MainActor
@Suite struct CombineOperatorsTests {
    // MARK: - Functor Tests

    @Test func fmap() {
        var cancellables = Set<AnyCancellable>()
        let publisher = [1, 2, 3].publisher

        let doubled = Result<Int, Never>.Publisher.fmap { $0 * 2 }(publisher)

        var results: [Int] = []
        doubled.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [2, 4, 6])
    }

    @Test func functorIdentityLaw() {
        var cancellables = Set<AnyCancellable>()
        let publisher = [1, 2, 3].publisher

        let mapped = Result<Int, Never>.Publisher.fmap(id)(publisher)

        var originalResults: [Int] = []
        var mappedResults: [Int] = []

        publisher.sink(
            receiveCompletion: ignore,
            receiveValue: { originalResults.append($0) }
        )
        .store(in: &cancellables)

        mapped.sink(
            receiveCompletion: ignore,
            receiveValue: { mappedResults.append($0) }
        )
        .store(in: &cancellables)

        #expect(originalResults == mappedResults)
    }

    @Test func functorCompositionLaw() {
        var cancellables = Set<AnyCancellable>()
        let publisher = [1, 2, 3].publisher

        let f: @Sendable (Int) -> Int = { $0 * 2 }
        let g: @Sendable (Int) -> String = { "\($0)" }

        // fmap (g . f) == fmap g . fmap f
        let composed = (compose(f, g) <£> publisher)
        let separate = (g <£> (f <£> publisher))

        var composedResults: [String] = []
        var separateResults: [String] = []

        composed.sink(
            receiveCompletion: ignore,
            receiveValue: { composedResults.append($0) }
        )
        .store(in: &cancellables)

        separate.sink(
            receiveCompletion: ignore,
            receiveValue: { separateResults.append($0) }
        )
        .store(in: &cancellables)

        #expect(composedResults == separateResults)
    }

    @Test func functorOperators() {
        var cancellables = Set<AnyCancellable>()
        let publisher = [1, 2, 3].publisher

        // Test <£> operator
        let doubled = { $0 * 2 } <£> publisher

        var results: [Int] = []
        doubled.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [2, 4, 6])
    }

    @Test func mapReplace() {
        var cancellables = Set<AnyCancellable>()
        let publisher = [1, 2, 3].publisher

        // Test £> operator
        let replaced = publisher £> 99

        var results: [Int] = []
        replaced.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [99, 99, 99])
    }

    @Test func mapReplaceFlipped() {
        var cancellables = Set<AnyCancellable>()
        let publisher = [1, 2, 3].publisher

        // Test <£ operator
        let replaced = 42 <£ publisher

        var results: [Int] = []
        replaced.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [42, 42, 42])
    }

    // MARK: - Bimap Tests

    @Test func mapLeft() {
        var cancellables = Set<AnyCancellable>()
        let publisher = [1, 2, 3].publisher

        let doubled = publisher.mapLeft { $0 * 2 }

        var results: [Int] = []
        doubled.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [2, 4, 6])
    }

    @Test func mapRight() {
        var cancellables = Set<AnyCancellable>()
        enum TestError: Error {
            case original
            case mapped
        }

        let publisher = Fail<Int, TestError>(error: .original)

        let mapped = publisher.mapRight(const(TestError.mapped))

        var capturedError: TestError?
        mapped.sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    capturedError = error
                }
            },
            receiveValue: ignore
        )
        .store(in: &cancellables)

        #expect(capturedError == .mapped)
    }

    @Test func bimap() {
        var cancellables = Set<AnyCancellable>()
        enum TestError: Error {
            case original
            case mapped
        }

        let successPublisher = [1, 2, 3].publisher.setFailureType(to: TestError.self)
        let failurePublisher = Fail<Int, TestError>(error: .original)

        let bimappedSuccess = successPublisher.bimap({ $0 * 2 }, const(TestError.mapped))
        let bimappedFailure = failurePublisher.bimap({ $0 * 2 }, const(TestError.mapped))

        var results: [Int] = []
        bimappedSuccess.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        var capturedError: TestError?
        bimappedFailure.sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    capturedError = error
                }
            },
            receiveValue: ignore
        )
        .store(in: &cancellables)

        #expect(results == [2, 4, 6])
        #expect(capturedError == .mapped)
    }

    // MARK: - Applicative Tests

    @Test func basicLiftA2() {
        var cancellables = Set<AnyCancellable>()
        let publisher1 = [1, 2].publisher
        let publisher2 = [10, 20].publisher

        let add: @Sendable (Int, Int) -> Int = { $0 + $1 }
        let lifted = Result<Int, Never>.Publisher.liftA2(add)
        let result = lifted(publisher1, publisher2)

        var results: [Int] = []
        result.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [11, 22])
    }

    @Test func zip() {
        var cancellables = Set<AnyCancellable>()
        let publisher1 = [1, 2, 3].publisher
        let publisher2 = ["a", "b", "c"].publisher

        let zipped = Result<(Int, String), Never>.Publisher.zip(publisher1, publisher2)

        var results: [(Int, String)] = []
        zipped.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results.count == 3)
        #expect(results[0].0 == 1)
        #expect(results[0].1 == "a")
        #expect(results[1].0 == 2)
        #expect(results[1].1 == "b")
        #expect(results[2].0 == 3)
        #expect(results[2].1 == "c")
    }

    @Test func applyOperator() {
        var cancellables = Set<AnyCancellable>()
        let functions = [{ (x: Int) in x * 2 }, { (x: Int) in x + 10 }].publisher
        let values = [5, 3].publisher

        let applied = functions <*> values

        var results: [Int] = []
        applied.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [10, 13])
    }

    @Test func sequenceRight() {
        var cancellables = Set<AnyCancellable>()
        let publisher1 = [1, 2].publisher
        let publisher2 = [10, 20].publisher

        let result = publisher1 *> publisher2

        var results: [Int] = []
        result.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [10, 20])
    }

    @Test func sequenceLeft() {
        var cancellables = Set<AnyCancellable>()
        let publisher1 = [1, 2].publisher
        let publisher2 = [10, 20].publisher

        let result = publisher1 <* publisher2

        var results: [Int] = []
        result.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [1, 2])
    }

    // MARK: - Monad Tests

    @Test func bind() {
        var cancellables = Set<AnyCancellable>()
        let publisher = [1, 2].publisher

        let fn: @Sendable (Int) -> AnyPublisher<Int, Never> = { value in
            [value, value * 10].publisher.eraseToAnyPublisher()
        }

        let bound = Result<Int, Never>.Publisher.bind(fn)(publisher)

        var results: [Int] = []
        bound.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [1, 10, 2, 20])
    }

    @Test func bindOperator() {
        var cancellables = Set<AnyCancellable>()
        let publisher = [1, 2].publisher

        let result = publisher >>- { value in
            [value * 2].publisher
        }

        var results: [Int] = []
        result.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [2, 4])
    }

    @Test func flippedBindOperator() {
        var cancellables = Set<AnyCancellable>()
        let publisher = [1, 2].publisher

        let fn: @Sendable (Int) -> AnyPublisher<Int, Never> = { value in
            [value * 3].publisher.eraseToAnyPublisher()
        }

        let result = fn -<< publisher

        var results: [Int] = []
        result.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [3, 6])
    }

    @Test func kleisliComposition() {
        var cancellables = Set<AnyCancellable>()
        let fn1: @Sendable (Int) -> AnyPublisher<Int, Never> = { [$0 * 2].publisher.eraseToAnyPublisher() }
        let fn2: @Sendable (Int) -> AnyPublisher<String, Never> = { ["\($0)"].publisher.eraseToAnyPublisher() }

        let composed = AnyPublisher<Int, Never>.kleisli(fn1, fn2)
        let result = composed(5)

        var results: [String] = []
        result.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == ["10"])
    }

    @Test func kleisliOperator() {
        var cancellables = Set<AnyCancellable>()
        let fn1: @Sendable (Int) -> AnyPublisher<Int, Never> = { [$0 * 2].publisher.eraseToAnyPublisher() }
        let fn2: @Sendable (Int) -> AnyPublisher<String, Never> = { ["\($0)"].publisher.eraseToAnyPublisher() }

        let composed = fn1 >=> fn2
        let result = composed(5)

        var results: [String] = []
        result.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == ["10"])
    }

    @Test func flippedFmapOperator() {
        var cancellables = Set<AnyCancellable>()
        let publisher = [1, 2, 3].publisher

        let result = publisher <&> { $0 * 2 }

        var results: [Int] = []
        result.sink(
            receiveCompletion: ignore,
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)

        #expect(results == [2, 4, 6])
    }

    @Test func monadLeftIdentity() {
        var cancellables = Set<AnyCancellable>()
        let value = 5

        let f: @Sendable (Int) -> AnyPublisher<Int, Never> = { [$0 * 2].publisher.eraseToAnyPublisher() }

        // return a >>= f == f a
        let left = Just(value).eraseToAnyPublisher() >>- f
        let right = f(value)

        var leftResults: [Int] = []
        var rightResults: [Int] = []

        left.sink(
            receiveCompletion: ignore,
            receiveValue: { leftResults.append($0) }
        )
        .store(in: &cancellables)

        right.sink(
            receiveCompletion: ignore,
            receiveValue: { rightResults.append($0) }
        )
        .store(in: &cancellables)

        #expect(leftResults == rightResults)
    }

    @Test func monadRightIdentity() {
        var cancellables = Set<AnyCancellable>()
        let publisher = [1, 2, 3].publisher.eraseToAnyPublisher()

        // m >>= return == m
        let bound = publisher >>- { Just($0).eraseToAnyPublisher() }

        var originalResults: [Int] = []
        var boundResults: [Int] = []

        publisher.sink(
            receiveCompletion: ignore,
            receiveValue: { originalResults.append($0) }
        )
        .store(in: &cancellables)

        bound.sink(
            receiveCompletion: ignore,
            receiveValue: { boundResults.append($0) }
        )
        .store(in: &cancellables)

        #expect(originalResults == boundResults)
    }

    @Test func monadAssociativity() {
        var cancellables = Set<AnyCancellable>()
        let publisher = [1].publisher

        let f: @Sendable (Int) -> AnyPublisher<Int, Never> = { [$0 * 2].publisher.eraseToAnyPublisher() }
        let g: @Sendable (Int) -> AnyPublisher<Int, Never> = { [$0 + 10].publisher.eraseToAnyPublisher() }

        // (m >>= f) >>= g == m >>= (\x -> f x >>= g)
        let left = (publisher >>- f) >>- g
        let right = publisher >>- { x in
            f(x).eraseToAnyPublisher().flatMap(g).eraseToAnyPublisher()
        }

        var leftResults: [Int] = []
        var rightResults: [Int] = []

        left.sink(
            receiveCompletion: ignore,
            receiveValue: { leftResults.append($0) }
        )
        .store(in: &cancellables)

        right.sink(
            receiveCompletion: ignore,
            receiveValue: { rightResults.append($0) }
        )
        .store(in: &cancellables)

        #expect(leftResults == rightResults)
    }
}
#endif
