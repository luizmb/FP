// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import CoreFPOperators
    import Testing

    /// Operator syntax for the Publisher ordered-concat monad and its bind-derived applicative.
    @MainActor
    @Suite struct PublisherConcatOperatorsTests {
        struct Step {
            let id: Int
            let inner: AnyPublisher<Int, Never>
        }

        enum Boom: Error, Equatable {
            case boom
        }

        private func collect<A, E: Error>(_ publisher: any Publisher<A, E>) -> [A] {
            var results: [A] = []
            var cancellables = Set<AnyCancellable>()
            publisher.eraseToAnyPublisher()
                .sink(receiveCompletion: { _ in }, receiveValue: { results.append($0) })
                .store(in: &cancellables)
            return results
        }

        private let f: @Sendable (Int) -> AnyPublisher<Int, Never> = { a in [a, a * 10].publisher.eraseToAnyPublisher() }
        private let g: @Sendable (Int) -> AnyPublisher<Int, Never> = { a in [a + 1, a + 2].publisher.eraseToAnyPublisher() }

        // MARK: - Publisher

        @Test func bindOperatorIsOrderedAndLossless() {
            let upstream = PassthroughSubject<Step, Never>()
            let innerA = PassthroughSubject<Int, Never>()
            var results: [Int] = []
            var cancellables = Set<AnyCancellable>()

            (upstream >>- { (step: Step) in step.inner.prepend(step.id) })
                .eraseToAnyPublisher()
                .sink(receiveCompletion: { _ in }, receiveValue: { results.append($0) })
                .store(in: &cancellables)

            upstream.send(Step(id: 1, inner: innerA.eraseToAnyPublisher()))
            upstream.send(Step(id: 2, inner: Just(20).eraseToAnyPublisher()))
            innerA.send(10)
            innerA.send(completion: .finished)

            #expect(results == [1, 10, 2, 20])
        }

        @Test func flippedBindOperatorIsConcat() {
            #expect(collect(f -<< [1, 2].publisher) == [1, 10, 2, 20])
        }

        @Test func kleisliOperatorsAreConcat() {
            #expect(collect((f >=> g)(1)) == [2, 3, 11, 12])
            #expect(collect((g <=< f)(1)) == [2, 3, 11, 12])
        }

        @Test func applyOperatorIsBindDerivedAp() {
            let fns: [@Sendable (Int) -> Int] = [{ $0 + 100 }, { $0 * 2 }]
            #expect(collect(fns.publisher <*> [1, 2].publisher) == [101, 102, 2, 4])
        }

        @Test func sequenceOperatorsAreBindDerived() {
            #expect(collect([1, 2].publisher *> ["a", "b"].publisher) == ["a", "b", "a", "b"])
            #expect(collect([1, 2].publisher <* ["a", "b"].publisher) == [1, 1, 2, 2])
        }

        // MARK: - PublisherTOptional

        private let fOpt: @Sendable (Int) -> AnyPublisher<Int?, Never> = { a in [a, nil, a * 10].publisher.eraseToAnyPublisher() }
        private let gOpt: @Sendable (Int) -> AnyPublisher<Int?, Never> = { a in Just(a + 1).eraseToAnyPublisher() }

        private func opt(_ values: [Int?]) -> AnyPublisher<Int?, Never> {
            values.publisher.eraseToAnyPublisher()
        }

        @Test func publisherTOptionalBindOperators() {
            #expect(collect(opt([1, nil]) >>- fOpt) == [1, nil, 10, nil])
            #expect(collect(fOpt -<< opt([2])) == [2, nil, 20])
            #expect(collect((fOpt >=> gOpt)(1)) == [2, nil, 11])
            #expect(collect((gOpt <=< fOpt)(1)) == [2, nil, 11])
        }

        @Test func publisherTOptionalApplicativeOperators() {
            let fns: [(@Sendable (Int) -> Int)?] = [{ $0 + 100 }, nil]
            let fnsPublisher: AnyPublisher<(@Sendable (Int) -> Int)?, Never> = fns.publisher.eraseToAnyPublisher()
            #expect(collect(fnsPublisher <*> opt([1, 2])) == [101, 102, nil])
            #expect(collect(opt([1, nil]) *> opt([10, 20])) == [10, 20, nil])
            #expect(collect(opt([1, nil]) <* opt([10, 20])) == [1, 1, nil])
        }

        // MARK: - PublisherTResult

        private let fRes: @Sendable (Int) -> AnyPublisher<Result<Int, Boom>, Never> = { a in
            [Result<Int, Boom>.success(a), .failure(.boom)].publisher.eraseToAnyPublisher()
        }

        private let gRes: @Sendable (Int) -> AnyPublisher<Result<Int, Boom>, Never> = { a in
            Just(Result<Int, Boom>.success(a + 1)).eraseToAnyPublisher()
        }

        private func res(_ values: [Result<Int, Boom>]) -> AnyPublisher<Result<Int, Boom>, Never> {
            values.publisher.eraseToAnyPublisher()
        }

        @Test func publisherTResultBindOperators() {
            #expect(collect(res([.success(1), .success(2)]) >>- fRes) == [.success(1), .failure(.boom), .success(2), .failure(.boom)])
            #expect(collect(fRes -<< res([.failure(.boom)])) == [.failure(.boom)])
            #expect(collect((fRes >=> gRes)(1)) == [.success(2), .failure(.boom)])
            #expect(collect((gRes <=< fRes)(1)) == [.success(2), .failure(.boom)])
        }

        @Test func publisherTResultApplicativeOperators() {
            let fns: [Result<@Sendable (Int) -> Int, Boom>] = [.success { $0 + 100 }, .failure(.boom)]
            let fnsPublisher: AnyPublisher<Result<@Sendable (Int) -> Int, Boom>, Never> = fns.publisher.eraseToAnyPublisher()
            let values = res([.success(1), .success(2)])
            #expect(collect(fnsPublisher <*> values) == [.success(101), .success(102), .failure(.boom)])
            #expect(collect(res([.success(1), .failure(.boom)]) *> values) == [.success(1), .success(2), .failure(.boom)])
            #expect(collect(res([.success(7), .failure(.boom)]) <* values) == [.success(7), .success(7), .failure(.boom)])
        }
    }
#endif
