#if canImport(Combine)
import Combine
@testable import CoreFP
import Testing

@Suite struct PublisherTransformerTests {
    // Helper to collect values from synchronous publishers
    private func collect<A, E: Error>(_ publisher: AnyPublisher<A, E>) -> [A] {
        var results: [A] = []
        var cancellables = Set<AnyCancellable>()
        publisher.sink(
            receiveCompletion: { _ in },
            receiveValue: { results.append($0) }
        )
        .store(in: &cancellables)
        return results
    }

    // MARK: - PublisherTOptional

    @Test func publisherTOptionalMapT() {
        let pub: AnyPublisher<Int?, Never> = [1, nil, 3].publisher.map { $0 as Int? }.eraseToAnyPublisher()
        let result = mapTPublisherOptional({ $0 * 2 }, pub)
        #expect(collect(result) == [2, nil, 6])
    }

    @Test func publisherTOptionalLiftA2() {
        let pubA: AnyPublisher<Int?, Never> = [1, nil].publisher.map { $0 as Int? }.eraseToAnyPublisher()
        let pubB: AnyPublisher<Int?, Never> = [10, 20].publisher.map { $0 as Int? }.eraseToAnyPublisher()
        let result = liftA2PublisherOptional(+)(pubA, pubB)
        #expect(collect(result) == [11, nil])
    }

    @Test func publisherTOptionalFlatMapT() {
        let pub: AnyPublisher<Int?, Never> = [1, nil].publisher.map { $0 as Int? }.eraseToAnyPublisher()
        let result = flatMapTPublisherOptional(pub) { n in
            Just(Optional.some(n * 2)).setFailureType(to: Never.self).eraseToAnyPublisher()
        }
        #expect(collect(result) == [2, nil])
    }

    // MARK: - PublisherTArray

    @Test func publisherTArrayMapT() {
        let pub: AnyPublisher<[Int], Never> = [[1, 2], [3, 4]].publisher.eraseToAnyPublisher()
        let result = mapTPublisherArray({ $0 * 2 }, pub)
        #expect(collect(result) == [[2, 4], [6, 8]])
    }

    @Test func publisherTArrayLiftA2() {
        let pubA: AnyPublisher<[Int], Never> = [[1, 2]].publisher.eraseToAnyPublisher()
        let pubB: AnyPublisher<[Int], Never> = [[10, 20]].publisher.eraseToAnyPublisher()
        let result = liftA2PublisherArray(+)(pubA, pubB)
        #expect(collect(result) == [[11, 21, 12, 22]])
    }

    // MARK: - PublisherTResult

    @Test func publisherTResultMapTSuccess() {
        let pub: AnyPublisher<Result<Int, Never>, Never> = [Result<Int, Never>.success(5)].publisher.eraseToAnyPublisher()
        let result = mapTPublisherResult({ $0 * 2 }, pub)
        #expect(collect(result) == [.success(10)])
    }

    @Test func publisherTResultFlatMapTSuccess() {
        let pub: AnyPublisher<Result<Int, Never>, Never> = [Result<Int, Never>.success(5)].publisher.eraseToAnyPublisher()
        let result = flatMapTPublisherResult(pub) { n in
            Just(Result<String, Never>.success("\(n)")).eraseToAnyPublisher()
        }
        #expect(collect(result) == [.success("5")])
    }
}
#endif
