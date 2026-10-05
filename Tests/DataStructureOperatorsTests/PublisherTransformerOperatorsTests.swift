// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import CoreFPOperators
    import DataStructure
    import DataStructureOperators
    import Testing

    @MainActor
    @Suite struct PublisherTransformerOperatorsTests {
        enum TestError: Error, Equatable {
            case test
        }

        // MARK: - PublisherTStateful (AnyPublisher<Stateful<S, A>, E>)

        @Test func publisherTStatefulSequenceRightOperator() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Stateful<Int, Int> { s in s + 1 }).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Stateful<Int, Int> { s in s * 2 }).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let result = pubA *> pubB

            var capturedValue: Int?
            result.sink(
                receiveCompletion: ignore,
                receiveValue: { stateful in capturedValue = stateful.eval(10) }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 20)
        }

        @Test func publisherTStatefulSequenceLeftOperator() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Stateful<Int, Int> { s in s + 1 }).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Stateful<Int, Int> { s in s * 2 }).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let result = pubA <* pubB

            var capturedValue: Int?
            result.sink(
                receiveCompletion: ignore,
                receiveValue: { stateful in capturedValue = stateful.eval(10) }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 11)
        }

        // MARK: - StatefulTPublisher (Stateful<S, any Publisher<A, E>>)

        // Note: no monad operators (>>-/-<</>=>): Combine closures cannot capture the `inout` state.

        @Test func statefulTPublisherApplyOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let sf = Stateful<Int, any Publisher<@Sendable (Int) -> Int, TestError>> { s in
                let offset = s
                let addOffset: @Sendable (Int) -> Int = { $0 + offset }
                return Just(addOffset).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }
            // `_` is inout S — `const` takes (T) -> A not (inout T) -> A
            // swiftlint:disable:next closure_ignoring_args
            let sa = Stateful<Int, any Publisher<Int, TestError>> { _ in
                Just(10).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }

            let result = StatefulTPublisher(sf) <*> StatefulTPublisher(sa)

            var state = 5
            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.rawValue.run(&state)
                .eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 15)
        }

        @Test func statefulTPublisherSequenceRightOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            // `_` is inout S — `const` takes (T) -> A not (inout T) -> A
            // swiftlint:disable:next closure_ignoring_args
            let sa = Stateful<Int, any Publisher<Int, TestError>> { _ in
                Just(1).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }
            // swiftlint:disable:next closure_ignoring_args
            let sb = Stateful<Int, any Publisher<Int, TestError>> { _ in
                Just(2).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }

            let result = StatefulTPublisher(sa) *> StatefulTPublisher(sb)

            var state = 5
            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.rawValue.run(&state)
                .eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 2)
        }

        @Test func statefulTPublisherSequenceLeftOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            // `_` is inout S — `const` takes (T) -> A not (inout T) -> A
            // swiftlint:disable:next closure_ignoring_args
            let sa = Stateful<Int, any Publisher<Int, TestError>> { _ in
                Just(1).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }
            // swiftlint:disable:next closure_ignoring_args
            let sb = Stateful<Int, any Publisher<Int, TestError>> { _ in
                Just(2).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }

            let result = StatefulTPublisher(sa) <* StatefulTPublisher(sb)

            var state = 5
            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.rawValue.run(&state)
                .eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 1)
        }

        // MARK: - PublisherTWriter (AnyPublisher<Writer<W, A>, E>)

        @Test func publisherTWriterSequenceRightOperator() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Writer<[String], Int>(2, ["a"])).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Writer<[String], Int>(3, ["b"])).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let result = pubA *> pubB

            var capturedValue: Int?
            var capturedLog: [String] = []
            result.sink(
                receiveCompletion: ignore,
                receiveValue: { writer in
                    capturedValue = writer.value
                    capturedLog = writer.log
                }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 3)
            #expect(capturedLog == ["a", "b"])
        }

        @Test func publisherTWriterSequenceLeftOperator() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Writer<[String], Int>(2, ["a"])).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Writer<[String], Int>(3, ["b"])).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let result = pubA <* pubB

            var capturedValue: Int?
            var capturedLog: [String] = []
            result.sink(
                receiveCompletion: ignore,
                receiveValue: { writer in
                    capturedValue = writer.value
                    capturedLog = writer.log
                }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 2)
            #expect(capturedLog == ["a", "b"])
        }

        @Test func publisherTWriterBindOperator() {
            var cancellables = Set<AnyCancellable>()
            let writer = Writer<[String], Int>(2, ["outer"])
            let publisher = Just(writer).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let bound = publisher >>- { (value: Int) in
                Just(Writer<[String], String>("\(value * 10)", ["inner"])).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }

            var captured: Writer<[String], String>?
            bound.sink(
                receiveCompletion: ignore,
                receiveValue: { writer in captured = writer }
            )
            .store(in: &cancellables)

            #expect(captured?.value == "20")
            #expect(captured?.log == ["outer", "inner"])
        }

        @Test func publisherTWriterFlippedBindOperator() {
            var cancellables = Set<AnyCancellable>()
            let writer = Writer<[String], Int>(2, ["outer"])
            let publisher = Just(writer).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let fn: @Sendable (Int) -> AnyPublisher<Writer<[String], String>, TestError> = { value in
                Just(Writer<[String], String>("\(value * 10)", ["inner"])).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }
            let bound = fn -<< publisher

            var captured: Writer<[String], String>?
            bound.sink(
                receiveCompletion: ignore,
                receiveValue: { writer in captured = writer }
            )
            .store(in: &cancellables)

            #expect(captured?.value == "20")
            #expect(captured?.log == ["outer", "inner"])
        }

        // MARK: - WriterTPublisher (Writer<W, any Publisher<A, E>>)

        @Test func writerTPublisherApplyOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let wf = Writer<[String], any Publisher<@Sendable (Int) -> Int, TestError>>(
                Just<@Sendable (Int) -> Int> { $0 + 1 }.setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["fn"]
            )
            let wa = Writer<[String], any Publisher<Int, TestError>>(
                Just(10).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["arg"]
            )

            let result = (WriterTPublisher(wf) <*> WriterTPublisher(wa)).rawValue

            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 11)
            #expect(result.log == ["fn", "arg"])
        }

        @Test func writerTPublisherSequenceRightOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let lhs = Writer<[String], any Publisher<Int, TestError>>(
                Just(2).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["a"]
            )
            let rhs = Writer<[String], any Publisher<Int, TestError>>(
                Just(3).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["b"]
            )

            let result = (WriterTPublisher(lhs) *> WriterTPublisher(rhs)).rawValue

            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 3)
            #expect(result.log == ["a", "b"])
        }

        @Test func writerTPublisherSequenceLeftOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let lhs = Writer<[String], any Publisher<Int, TestError>>(
                Just(2).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["a"]
            )
            let rhs = Writer<[String], any Publisher<Int, TestError>>(
                Just(3).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["b"]
            )

            let result = (WriterTPublisher(lhs) <* WriterTPublisher(rhs)).rawValue

            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 2)
            #expect(result.log == ["a", "b"])
        }

        // MARK: - PublisherTEither (AnyPublisher<Either<L, A>, E>)

        @Test func publisherTEitherSequenceRightOperator() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Either<String, Int>.right(2)).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Either<String, Int>.right(3)).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let result = pubA *> pubB

            var captured: Either<String, Int>?
            result.sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .right(3))
        }

        @Test func publisherTEitherSequenceLeftOperator() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Either<String, Int>.right(2)).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Either<String, Int>.right(3)).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let result = pubA <* pubB

            var captured: Either<String, Int>?
            result.sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .right(2))
        }

        @Test func publisherTEitherBindOperator() {
            var cancellables = Set<AnyCancellable>()
            let right: Either<String, Int> = .right(2)
            let publisher = Just(right).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let bound = publisher >>- { value in
                Just(Either<String, Int>.right(value * 10)).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }

            var captured: Either<String, Int>?
            bound.sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .right(20))
        }

        @Test func publisherTEitherBindOperatorLeftShortCircuits() {
            var cancellables = Set<AnyCancellable>()
            let left: Either<String, Int> = .left("boom")
            let publisher = Just(left).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let bound = publisher >>- { value in
                Just(Either<String, Int>.right(value * 10)).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }

            var captured: Either<String, Int>?
            bound.sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .left("boom"))
        }

        @Test func publisherTEitherFlippedBindOperator() {
            var cancellables = Set<AnyCancellable>()
            let right: Either<String, Int> = .right(2)
            let publisher = Just(right).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let fn: @Sendable (Int) -> AnyPublisher<Either<String, Int>, TestError> = { value in
                Just(Either<String, Int>.right(value + 1)).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }
            let bound = fn -<< publisher

            var captured: Either<String, Int>?
            bound.sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .right(3))
        }
    }
#endif
