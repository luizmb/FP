// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    @testable import CoreFP
    import Testing

    /// Publisher follows Haskell stream semantics: bind is ordered concat, `<*>` is the bind-derived `ap`.
    @MainActor
    @Suite struct PublisherConcatLawTests {
        /// An upstream step carrying the inner publisher its continuation will run.
        struct Step {
            let id: Int
            let inner: AnyPublisher<Int, Never>
        }

        private func collect<A, E: Error>(_ publisher: any Publisher<A, E>) -> [A] {
            var results: [A] = []
            var cancellables = Set<AnyCancellable>()
            publisher.eraseToAnyPublisher()
                .sink(receiveCompletion: { _ in }, receiveValue: { results.append($0) })
                .store(in: &cancellables)
            return results
        }

        private func just(_ value: Int) -> AnyPublisher<Int, Never> {
            Just(value).eraseToAnyPublisher()
        }

        private let f: @Sendable (Int) -> AnyPublisher<Int, Never> = { a in [a, a * 10].publisher.eraseToAnyPublisher() }
        private let g: @Sendable (Int) -> AnyPublisher<Int, Never> = { a in [a + 1, a + 2].publisher.eraseToAnyPublisher() }
        private let unit: @Sendable (Int) -> AnyPublisher<Int, Never> = { a in Just(a).eraseToAnyPublisher() }

        // MARK: - Monad laws

        @Test func leftIdentity() {
            let lhs = AnyPublisher<Int, Never>.bind(f)(just(3))
            #expect(collect(lhs) == collect(f(3)))
        }

        @Test func rightIdentity() {
            let m = [1, 2, 3].publisher.eraseToAnyPublisher()
            #expect(collect(AnyPublisher<Int, Never>.bind(unit)(m)) == [1, 2, 3])
        }

        @Test func associativity() {
            let m = [1, 2].publisher.eraseToAnyPublisher()
            let lhs = AnyPublisher<Int, Never>.bind(g)(AnyPublisher<Int, Never>.bind(f)(m))
            let composed = AnyPublisher<Int, Never>.kleisli(f, g)
            let rhs = AnyPublisher<Int, Never>.bind { (a: Int) in composed(a).eraseToAnyPublisher() }(m)
            #expect(collect(lhs) == collect(rhs))
            #expect(collect(lhs) == [2, 3, 11, 12, 3, 4, 21, 22])
        }

        @Test func kleisliBackMatchesKleisli() {
            let forward = AnyPublisher<Int, Never>.kleisli(f, g)
            let backward = AnyPublisher<Int, Never>.kleisliBack(g, f)
            #expect(collect(forward(5)) == collect(backward(5)))
        }

        // MARK: - Ordered, lossless bind

        @Test func bindIsOrderedAndLosslessWithSubjectUpstream() {
            let upstream = PassthroughSubject<Step, Never>()
            let innerA = PassthroughSubject<Int, Never>()
            let innerB = PassthroughSubject<Int, Never>()
            var results: [Int] = []
            var finished = false
            var cancellables = Set<AnyCancellable>()

            AnyPublisher<Step, Never>.bind { (step: Step) in step.inner.prepend(step.id) }(upstream)
                .eraseToAnyPublisher()
                .sink(receiveCompletion: { completion in finished = completion == .finished }, receiveValue: { results.append($0) })
                .store(in: &cancellables)

            upstream.send(Step(id: 1, inner: innerA.eraseToAnyPublisher()))
            // innerA is still running: these must be buffered, not dropped nor merged
            upstream.send(Step(id: 2, inner: innerB.eraseToAnyPublisher()))
            upstream.send(Step(id: 3, inner: Empty().eraseToAnyPublisher()))
            upstream.send(completion: .finished)
            innerA.send(10)
            innerA.send(11)
            #expect(results == [1, 10, 11])
            #expect(finished == false)

            innerA.send(completion: .finished)
            innerB.send(20)
            innerB.send(completion: .finished)

            #expect(results == [1, 10, 11, 2, 20, 3])
            #expect(finished)
        }

        @Test func kleisliIsOrderedConcat() {
            let composed = AnyPublisher<Int, Never>.kleisli(f, g)
            #expect(collect(composed(1)) == [2, 3, 11, 12])
        }

        // MARK: - Applicative == ap

        @Test func applyIsCartesianInFunctionOrder() {
            let fns: [@Sendable (Int) -> Int] = [{ $0 + 100 }, { $0 * 2 }]
            let result = AnyPublisher<Int, Never>.apply(fns.publisher, [1, 2].publisher)
            #expect(collect(result) == [101, 102, 2, 4])
        }

        @Test func applyEqualsBindDerivedAp() {
            let fns: [@Sendable (Int) -> Int] = [{ $0 + 100 }, { $0 * 2 }, { -$0 }]
            let values = [1, 2, 3]
            let applied = AnyPublisher<Int, Never>.apply(fns.publisher, values.publisher)
            let ap = AnyPublisher<@Sendable (Int) -> Int, Never>.bind { (fn: @Sendable (Int) -> Int) in
                values.publisher.map(fn)
            }(fns.publisher)
            #expect(collect(applied) == collect(ap))
        }

        @Test func liftA2EqualsBindDerivedAp() {
            let add: @Sendable (Int, Int) -> Int = { $0 * 10 + $1 }
            let rhs = [1, 2]
            let lifted = AnyPublisher<Int, Never>.liftA2(add)([1, 2, 3].publisher, rhs.publisher)
            let ap = AnyPublisher<Int, Never>.bind { (a: Int) in rhs.publisher.map { add(a, $0) } }([1, 2, 3].publisher)
            #expect(collect(lifted) == collect(ap))
            #expect(collect(lifted) == [11, 12, 21, 22, 31, 32])
        }

        @Test func seqRightRunsRightOncePerLeftElement() {
            let result = AnyPublisher<String, Never>.seqRight([1, 2].publisher, ["a", "b"].publisher)
            #expect(collect(result) == ["a", "b", "a", "b"])
        }

        @Test func seqLeftKeepsLeftOncePerRightElement() {
            let result = AnyPublisher<Int, Never>.seqLeft([1, 2].publisher, ["a", "b"].publisher)
            #expect(collect(result) == [1, 1, 2, 2])
        }

        @Test func seqRightWithEmptyLeftIsEmpty() {
            let result = AnyPublisher<Int, Never>.seqRight(Empty<Int, Never>(), [1, 2].publisher)
            #expect(collect(result).isEmpty)
        }

        // MARK: - zip stays pairwise

        @Test func zipIsPairwise() {
            let zipped = AnyPublisher<(Int, String), Never>.zip([1, 2, 3].publisher, ["a", "b"].publisher)
            let pairs = collect(zipped)
            #expect(pairs.map(\.0) == [1, 2])
            #expect(pairs.map(\.1) == ["a", "b"])
        }

        // MARK: - PublisherTOptional

        private let optValues: [Int?] = [1, nil, 2]
        private func optPublisher(_ values: [Int?]) -> AnyPublisher<Int?, Never> {
            values.publisher.eraseToAnyPublisher()
        }

        @Test func publisherTOptionalMonadLaws() {
            let fOpt: @Sendable (Int) -> AnyPublisher<Int?, Never> = { a in [a, nil, a * 10].publisher.eraseToAnyPublisher() }
            let gOpt: @Sendable (Int) -> AnyPublisher<Int?, Never> = { a in [a + 1].publisher.eraseToAnyPublisher() }
            let pureOpt: @Sendable (Int) -> AnyPublisher<Int?, Never> = { a in Just(a).eraseToAnyPublisher() }
            let m = optPublisher(optValues)

            #expect(collect(flatMapTPublisherOptional(pureOpt(4), fOpt)) == collect(fOpt(4)))
            #expect(collect(flatMapTPublisherOptional(m, pureOpt)) == optValues)
            let lhs = flatMapTPublisherOptional(flatMapTPublisherOptional(m, fOpt), gOpt)
            let rhs = flatMapTPublisherOptional(m, kleisliT(fOpt, gOpt))
            #expect(collect(lhs) == collect(rhs))
            #expect(collect(lhs) == [2, nil, 11, nil, 3, nil, 21])
        }

        @Test func publisherTOptionalApEqualsBindDerived() {
            let fns: [(@Sendable (Int) -> Int)?] = [{ $0 + 100 }, nil, { $0 * 2 }]
            let values = optValues
            let fnsPublisher: AnyPublisher<(@Sendable (Int) -> Int)?, Never> = fns.publisher.eraseToAnyPublisher()
            let applied = applyPublisherOptional(fnsPublisher, optPublisher(values))
            let ap = flatMapTPublisherOptional(fnsPublisher) { fn in
                mapTPublisherOptional(fn, values.publisher.eraseToAnyPublisher())
            }
            #expect(collect(applied) == collect(ap))
            #expect(collect(applied) == [101, nil, 102, nil, 2, nil, 4])
        }

        @Test func publisherTOptionalSeqAndLiftA2() {
            let lhs = optPublisher([1, nil, 2])
            let rhs = optPublisher([10, 20])
            #expect(collect(seqRightPublisherOptional(lhs, rhs)) == [10, 20, nil, 10, 20])
            #expect(collect(seqLeftPublisherOptional(lhs, rhs)) == [1, 1, nil, 2, 2])
            #expect(collect(liftA2PublisherOptional { (a: Int, b: Int) in a + b }(lhs, rhs)) == [11, 21, nil, 12, 22])
        }

        // MARK: - PublisherTResult

        enum Boom: Error, Equatable {
            case boom
        }

        private func resPublisher(_ values: [Result<Int, Boom>]) -> AnyPublisher<Result<Int, Boom>, Never> {
            values.publisher.eraseToAnyPublisher()
        }

        @Test func publisherTResultMonadLaws() {
            let fRes: @Sendable (Int) -> AnyPublisher<Result<Int, Boom>, Never> = { a in
                [Result<Int, Boom>.success(a), .failure(.boom), .success(a * 10)].publisher.eraseToAnyPublisher()
            }
            let gRes: @Sendable (Int) -> AnyPublisher<Result<Int, Boom>, Never> = { a in
                Just(Result<Int, Boom>.success(a + 1)).eraseToAnyPublisher()
            }
            let pureRes: @Sendable (Int) -> AnyPublisher<Result<Int, Boom>, Never> = { a in
                Just(Result<Int, Boom>.success(a)).eraseToAnyPublisher()
            }
            let values: [Result<Int, Boom>] = [.success(1), .failure(.boom), .success(2)]
            let m = resPublisher(values)

            #expect(collect(flatMapTPublisherResult(pureRes(4), fRes)) == collect(fRes(4)))
            #expect(collect(flatMapTPublisherResult(m, pureRes)) == values)
            let lhs = flatMapTPublisherResult(flatMapTPublisherResult(m, fRes), gRes)
            let rhs = flatMapTPublisherResult(m, kleisliT(fRes, gRes))
            #expect(collect(lhs) == collect(rhs))
            let expected: [Result<Int, Boom>] = [
                .success(2), .failure(.boom), .success(11), .failure(.boom), .success(3), .failure(.boom), .success(21)
            ]
            #expect(collect(lhs) == expected)
        }

        @Test func publisherTResultApEqualsBindDerived() {
            let fns: [Result<@Sendable (Int) -> Int, Boom>] = [.success { $0 + 100 }, .failure(.boom), .success { $0 * 2 }]
            let values: [Result<Int, Boom>] = [.success(1), .success(2)]
            let fnsPublisher: AnyPublisher<Result<@Sendable (Int) -> Int, Boom>, Never> = fns.publisher.eraseToAnyPublisher()
            let applied = applyPublisherResult(fnsPublisher, resPublisher(values))
            let ap = flatMapTPublisherResult(fnsPublisher) { fn in
                mapTPublisherResult(fn, values.publisher.eraseToAnyPublisher())
            }
            #expect(collect(applied) == collect(ap))
            #expect(collect(applied) == [.success(101), .success(102), .failure(.boom), .success(2), .success(4)])
        }

        @Test func publisherTResultSeqAndLiftA2() {
            let lhs = resPublisher([.success(1), .failure(.boom)])
            let rhs = resPublisher([.success(10), .success(20)])
            #expect(collect(seqRightPublisherResult(lhs, rhs)) == [.success(10), .success(20), .failure(.boom)])
            #expect(collect(seqLeftPublisherResult(lhs, rhs)) == [.success(1), .success(1), .failure(.boom)])
            let lifted = liftA2PublisherResult { (a: Int, b: Int) in a + b }(lhs, rhs)
            #expect(collect(lifted) == [.success(11), .success(21), .failure(.boom)])
        }
    }
#endif
