// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
@testable import CoreFPOperators
import Testing

// MARK: - Publisher transformer functor operators

#if canImport(Combine)
    import Combine

    @Suite struct PublisherTransformerFunctorTests {
        private var cancellables = Set<AnyCancellable>()

        // MARK: - Publisher<[A], E>

        @Test func publisherTArrayForwardFmap() {
            var cancellables = Set<AnyCancellable>()
            let pub: AnyPublisher<[Int], Never> = Just([1, 2, 3]).eraseToAnyPublisher()
            var result: [Int] = []
            ({ $0 * 2 } <£^> pub)
                .sink(receiveCompletion: ignore, receiveValue: { result = $0 })
                .store(in: &cancellables)
            #expect(result == [2, 4, 6])
        }

        @Test func publisherTArrayFlippedFmap() {
            var cancellables = Set<AnyCancellable>()
            let pub: AnyPublisher<[Int], Never> = Just([1, 2, 3]).eraseToAnyPublisher()
            var result: [Int] = []
            (pub <&^> { $0 * 2 })
                .sink(receiveCompletion: ignore, receiveValue: { result = $0 })
                .store(in: &cancellables)
            #expect(result == [2, 4, 6])
        }

        // MARK: - Publisher<A?, E>

        @Test func publisherTOptionalForwardFmap() {
            var cancellables = Set<AnyCancellable>()
            let pub: AnyPublisher<Int?, Never> = Just(Optional(5)).eraseToAnyPublisher()
            var result: Int?
            ({ $0 * 2 } <£^> pub)
                .sink(receiveCompletion: ignore, receiveValue: { result = $0 })
                .store(in: &cancellables)
            #expect(result == 10)
        }

        @Test func publisherTOptionalFlippedFmap() {
            var cancellables = Set<AnyCancellable>()
            let pub: AnyPublisher<Int?, Never> = Just(Optional(5)).eraseToAnyPublisher()
            var result: Int?
            (pub <&^> { $0 * 2 })
                .sink(receiveCompletion: ignore, receiveValue: { result = $0 })
                .store(in: &cancellables)
            #expect(result == 10)
        }

        @Test func publisherTOptionalNilPassthrough() {
            var cancellables = Set<AnyCancellable>()
            // Publisher emits both a value and nil to verify nil passthrough
            let values: [Int?] = [5, nil]
            let pub: AnyPublisher<Int?, Never> = values.publisher.eraseToAnyPublisher()
            var received: [Int?] = []
            ({ $0 * 2 } <£^> pub)
                .sink(receiveCompletion: ignore, receiveValue: { received.append($0) })
                .store(in: &cancellables)
            #expect(received == [10, nil])
        }

        // MARK: - Publisher<Result<A,E2>, E>

        @Test func publisherTResultForwardFmap() throws {
            var cancellables = Set<AnyCancellable>()
            enum Err: Error { case fail }
            let pub: AnyPublisher<Result<Int, Err>, Never> = Just(.success(3)).eraseToAnyPublisher()
            var result: Result<Int, Err>?
            ({ $0 * 2 } <£^> pub)
                .sink(receiveCompletion: ignore, receiveValue: { result = $0 })
                .store(in: &cancellables)
            #expect(try result?.get() == 6)
        }

        @Test func publisherTResultFlippedFmap() throws {
            var cancellables = Set<AnyCancellable>()
            enum Err: Error { case fail }
            let pub: AnyPublisher<Result<Int, Err>, Never> = Just(.success(3)).eraseToAnyPublisher()
            var result: Result<Int, Err>?
            (pub <&^> { $0 * 2 })
                .sink(receiveCompletion: ignore, receiveValue: { result = $0 })
                .store(in: &cancellables)
            #expect(try result?.get() == 6)
        }
    }
#endif

// MARK: - AsyncSequence transformer functor operators

@Suite struct AsyncSequenceTransformerFunctorTests {
    // MARK: - AsyncSequence<[A]>

    @Test func asyncSequenceTArrayForwardFmap() async {
        let seq = AsyncStream<[Int]> { continuation in
            continuation.yield([1, 2, 3])
            continuation.finish()
        }
        var result: [Int] = []
        for await v in ({ $0 * 2 } <£^> seq) {
            result = v
        }
        #expect(result == [2, 4, 6])
    }

    @Test func asyncSequenceTArrayFlippedFmap() async {
        let seq = AsyncStream<[Int]> { continuation in
            continuation.yield([1, 2, 3])
            continuation.finish()
        }
        var result: [Int] = []
        for await v in (seq <&^> { $0 * 2 }) {
            result = v
        }
        #expect(result == [2, 4, 6])
    }

    // MARK: - AsyncSequence<A?>

    @Test func asyncSequenceTOptionalForwardFmap() async {
        let seq = AsyncStream<Int?> { continuation in
            continuation.yield(5)
            continuation.yield(nil)
            continuation.finish()
        }
        var results: [Int?] = []
        for await v in ({ $0 * 2 } <£^> seq) {
            results.append(v)
        }
        #expect(results == [10, nil])
    }

    @Test func asyncSequenceTOptionalFlippedFmap() async {
        let seq = AsyncStream<Int?> { continuation in
            continuation.yield(5)
            continuation.yield(nil)
            continuation.finish()
        }
        var results: [Int?] = []
        for await v in (seq <&^> { $0 * 2 }) {
            results.append(v)
        }
        #expect(results == [10, nil])
    }

    // MARK: - AsyncSequence<Result<A,E>>

    @Test func asyncSequenceTResultForwardFmap() async {
        enum Err: Error, Equatable { case fail }
        let seq = AsyncStream<Result<Int, Err>> { continuation in
            continuation.yield(.success(3))
            continuation.yield(.failure(.fail))
            continuation.finish()
        }
        var results: [Result<Int, Err>] = []
        for await v in ({ $0 * 2 } <£^> seq) {
            results.append(v)
        }
        #expect(results == [.success(6), .failure(.fail)])
    }

    @Test func asyncSequenceTResultFlippedFmap() async {
        enum Err: Error, Equatable { case fail }
        let seq = AsyncStream<Result<Int, Err>> { continuation in
            continuation.yield(.success(3))
            continuation.yield(.failure(.fail))
            continuation.finish()
        }
        var results: [Result<Int, Err>] = []
        for await v in (seq <&^> { $0 * 2 }) {
            results.append(v)
        }
        #expect(results == [.success(6), .failure(.fail)])
    }
}
