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

        @Test func publisherTStatefulFmapOperator() {
            var cancellables = Set<AnyCancellable>()
            let stateful = Stateful<Int, Int> { s in
                s += 1
                return s
            }
            let publisher = Just(stateful).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let mapped = { (value: Int) in value * 10 } <£^> publisher

            var capturedValue: Int?
            mapped.sink(
                receiveCompletion: ignore,
                receiveValue: { stateful in capturedValue = stateful.eval(1) }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 20)
        }

        @Test func publisherTStatefulFlippedFmapOperator() {
            var cancellables = Set<AnyCancellable>()
            let stateful = Stateful<Int, Int> { s in s + 1 }
            let publisher = Just(stateful).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let mapped = publisher <&^> { $0 * 10 }

            var capturedValue: Int?
            mapped.sink(
                receiveCompletion: ignore,
                receiveValue: { stateful in capturedValue = stateful.eval(1) }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 20)
        }

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

        @Test func publisherTStatefulBindOperator() {
            var cancellables = Set<AnyCancellable>()
            let stateful = Stateful<Int, Int> { s in s + 1 }
            let publisher = Just(stateful).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let bound = publisher >>- { value in
                Stateful<Int, String> { s in "\(value)-\(s)" }
            }

            var capturedValue: String?
            bound.sink(
                receiveCompletion: ignore,
                receiveValue: { stateful in capturedValue = stateful.eval(10) }
            )
            .store(in: &cancellables)

            #expect(capturedValue == "11-10")
        }

        @Test func publisherTStatefulFlippedBindOperator() {
            var cancellables = Set<AnyCancellable>()
            let stateful = Stateful<Int, Int> { s in s + 1 }
            let publisher = Just(stateful).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let fn: @Sendable (Int) -> Stateful<Int, String> = { value in
                Stateful<Int, String> { s in "\(value)-\(s)" }
            }
            let bound = fn -<< publisher

            var capturedValue: String?
            bound.sink(
                receiveCompletion: ignore,
                receiveValue: { stateful in capturedValue = stateful.eval(10) }
            )
            .store(in: &cancellables)

            #expect(capturedValue == "11-10")
        }

        // MARK: - StatefulTPublisher (Stateful<S, any Publisher<A, E>>)

        // Note: no monad operators (>>-/-<</>=>) — see StatefulTPublisher+Monad.swift.

        @Test func statefulTPublisherFmapOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let stateful = Stateful<Int, any Publisher<Int, TestError>> { s in
                s += 1
                return Just(s).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }

            let mapped = { (value: Int) in value * 10 } <£^> stateful

            var state = 5
            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            mapped.run(&state)
                .eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 60)
            #expect(state == 6)
        }

        @Test func statefulTPublisherFlippedFmapOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let stateful = Stateful<Int, any Publisher<Int, TestError>> { s in
                Just(s).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }

            let mapped = stateful <&^> { $0 + 1 }

            var state = 5
            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            mapped.run(&state)
                .eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 6)
        }

        @Test func statefulTPublisherApplyOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let sf = Stateful<Int, any Publisher<(Int) -> Int, TestError>> { s in
                let offset = s
                let addOffset: @Sendable (Int) -> Int = { $0 + offset }
                return Just(addOffset).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }
            // `_` is inout S — `const` takes (T) -> A not (inout T) -> A
            // swiftlint:disable:next closure_ignoring_args
            let sa = Stateful<Int, any Publisher<Int, TestError>> { _ in
                Just(10).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }

            let result = sf <*> sa

            var state = 5
            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.run(&state)
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

            let result = sa *> sb

            var state = 5
            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.run(&state)
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

            let result = sa <* sb

            var state = 5
            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.run(&state)
                .eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 1)
        }

        // MARK: - PublisherTWriter (AnyPublisher<Writer<W, A>, E>)

        @Test func publisherTWriterFmapOperator() {
            var cancellables = Set<AnyCancellable>()
            let writer = Writer<[String], Int>(5, ["created"])
            let publisher = Just(writer).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let mapped = { (value: Int) in value * 10 } <£^> publisher

            var capturedValue: Int?
            var capturedLog: [String] = []
            mapped.sink(
                receiveCompletion: ignore,
                receiveValue: { writer in
                    capturedValue = writer.value
                    capturedLog = writer.log
                }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 50)
            #expect(capturedLog == ["created"])
        }

        @Test func publisherTWriterFlippedFmapOperator() {
            var cancellables = Set<AnyCancellable>()
            let writer = Writer<[String], Int>(5, ["created"])
            let publisher = Just(writer).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let mapped = publisher <&^> { $0 + 1 }

            var capturedValue: Int?
            mapped.sink(
                receiveCompletion: ignore,
                receiveValue: { writer in capturedValue = writer.value }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 6)
        }

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

            let bound = publisher >>- { value in
                Writer<[String], String>("\(value * 10)", ["inner"])
            }

            var capturedValue: String?
            bound.sink(
                receiveCompletion: ignore,
                receiveValue: { writer in capturedValue = writer.value }
            )
            .store(in: &cancellables)

            #expect(capturedValue == "20")
        }

        @Test func publisherTWriterFlippedBindOperator() {
            var cancellables = Set<AnyCancellable>()
            let writer = Writer<[String], Int>(2, ["outer"])
            let publisher = Just(writer).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let fn: @Sendable (Int) -> Writer<[String], String> = { value in
                Writer<[String], String>("\(value * 10)", ["inner"])
            }
            let bound = fn -<< publisher

            var capturedValue: String?
            bound.sink(
                receiveCompletion: ignore,
                receiveValue: { writer in capturedValue = writer.value }
            )
            .store(in: &cancellables)

            #expect(capturedValue == "20")
        }

        // MARK: - WriterTPublisher (Writer<W, any Publisher<A, E>>)

        @Test func writerTPublisherFmapOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let writer = Writer<[String], any Publisher<Int, TestError>>(
                Just(5).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["created"]
            )

            let mapped = { (value: Int) in value * 10 } <£^> writer

            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            mapped.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 50)
            #expect(mapped.log == ["created"])
        }

        @Test func writerTPublisherFlippedFmapOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let writer = Writer<[String], any Publisher<Int, TestError>>(
                Just(5).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["created"]
            )

            let mapped = writer <&^> { $0 + 1 }

            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            mapped.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 6)
        }

        @Test func writerTPublisherApplyOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let wf = Writer<[String], any Publisher<(Int) -> Int, TestError>>(
                Just { $0 + 1 }.setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["fn"]
            )
            let wa = Writer<[String], any Publisher<Int, TestError>>(
                Just(10).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["arg"]
            )

            let result = wf <*> wa

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

            let result = lhs *> rhs

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

            let result = lhs <* rhs

            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 2)
            #expect(result.log == ["a", "b"])
        }

        @Test func writerTPublisherBindOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let writer = Writer<[String], any Publisher<Int, TestError>>(
                Just(2).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["outer"]
            )

            let bound = writer >>- { value in
                Writer<[String], any Publisher<String, TestError>>(
                    Just("\(value * 10)").setFailureType(to: TestError.self).eraseToAnyPublisher(),
                    ["inner"]
                )
            }

            var cancellables = Set<AnyCancellable>()
            var capturedValue: String?
            bound.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == "20")
            #expect(bound.log == ["outer"])
        }

        @Test func writerTPublisherFlippedBindOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let writer = Writer<[String], any Publisher<Int, TestError>>(
                Just(2).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["outer"]
            )

            let fn: @Sendable (Int) -> Writer<[String], any Publisher<String, TestError>> = { value in
                Writer(
                    Just("\(value * 10)").setFailureType(to: TestError.self).eraseToAnyPublisher(),
                    ["inner"]
                )
            }
            let bound = fn -<< writer

            var cancellables = Set<AnyCancellable>()
            var capturedValue: String?
            bound.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == "20")
        }

        @Test func writerTPublisherKleisliCompositionOperator() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let parse: @Sendable (String) -> Writer<[String], any Publisher<Int, TestError>> = { s in
                Writer(
                    Just(Int(s) ?? 0).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                    ["parsed"]
                )
            }
            let double: @Sendable (Int) -> Writer<[String], any Publisher<Int, TestError>> = { n in
                Writer(
                    Just(n * 2).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                    ["doubled"]
                )
            }

            let pipeline = parse >=> double
            let result = pipeline("21")

            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 42)
            #expect(result.log == ["parsed"])
        }

        // MARK: - PublisherTEither (AnyPublisher<Either<L, A>, E>)

        @Test func publisherTEitherFmapOperator() {
            var cancellables = Set<AnyCancellable>()
            let right: Either<String, Int> = .right(5)
            let publisher = Just(right).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let mapped = { (value: Int) in value * 10 } <£^> publisher

            var captured: Either<String, Int>?
            mapped.sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .right(50))
        }

        @Test func publisherTEitherFlippedFmapOperator() {
            var cancellables = Set<AnyCancellable>()
            let right: Either<String, Int> = .right(5)
            let publisher = Just(right).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let mapped = publisher <&^> { $0 + 1 }

            var captured: Either<String, Int>?
            mapped.sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .right(6))
        }

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
