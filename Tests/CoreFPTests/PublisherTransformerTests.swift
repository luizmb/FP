// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
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

        @Test func publisherTOptionalMap() {
            let pub: AnyPublisher<Int?, Never> = [1, nil, 3].publisher.map { $0 as Int? }.eraseToAnyPublisher()
            let result = pub.publisherT.map { $0 * 2 }
            #expect(collect(result.rawValue) == [2, nil, 6])
        }

        @Test func publisherTOptionalLiftA2() {
            let pubA: AnyPublisher<Int?, Never> = [1, nil].publisher.map { $0 as Int? }.eraseToAnyPublisher()
            let pubB: AnyPublisher<Int?, Never> = [10, 20].publisher.map { $0 as Int? }.eraseToAnyPublisher()
            let result = PublisherTOptional<Never, Int>.liftA2(+)(pubA.publisherT, pubB.publisherT)
            // bind-derived: each left element runs the whole right stream; `nil` short-circuits once
            #expect(collect(result.rawValue) == [11, 21, nil])
        }

        @Test func publisherTOptionalFlatMap() {
            let pub: AnyPublisher<Int?, Never> = [1, nil].publisher.map { $0 as Int? }.eraseToAnyPublisher()
            let result = pub.publisherT.flatMap { n in
                PublisherTOptional(Just(Optional.some(n * 2)).setFailureType(to: Never.self).eraseToAnyPublisher())
            }
            #expect(collect(result.rawValue) == [2, nil])
        }

        // MARK: - PublisherTArray

        @Test func publisherTArrayMap() {
            let pub: AnyPublisher<[Int], Never> = [[1, 2], [3, 4]].publisher.eraseToAnyPublisher()
            let result = pub.publisherT.map { $0 * 2 }
            #expect(collect(result.rawValue) == [[2, 4], [6, 8]])
        }

        @Test func publisherTArrayLiftA2() {
            let pubA: AnyPublisher<[Int], Never> = [[1, 2]].publisher.eraseToAnyPublisher()
            let pubB: AnyPublisher<[Int], Never> = [[10, 20]].publisher.eraseToAnyPublisher()
            let result = PublisherTArray<Never, Int>.liftA2(+)(pubA.publisherT, pubB.publisherT)
            #expect(collect(result.rawValue) == [[11, 21, 12, 22]])
        }

        // MARK: - PublisherTResult

        @Test func publisherTResultMapSuccess() {
            let pub: AnyPublisher<Result<Int, Never>, Never> = [Result<Int, Never>.success(5)].publisher.eraseToAnyPublisher()
            let result = pub.publisherT.map { $0 * 2 }
            #expect(collect(result.rawValue) == [.success(10)])
        }

        @Test func publisherTResultFlatMapSuccess() {
            let pub: AnyPublisher<Result<Int, Never>, Never> = [Result<Int, Never>.success(5)].publisher.eraseToAnyPublisher()
            let result = pub.publisherT.flatMap { n in
                PublisherTResult(Just(Result<String, Never>.success("\(n)")).eraseToAnyPublisher())
            }
            #expect(collect(result.rawValue) == [.success("5")])
        }
    }
#endif
