// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import DataStructure
    import Testing

    @MainActor
    @Suite struct PublisherTransformerTests {
        enum TestError: Error, Equatable {
            case test
        }

        // MARK: - PublisherTStateful (AnyPublisher<Stateful<S, A>, E>)

        @Test func publisherTStatefulMapT() {
            var cancellables = Set<AnyCancellable>()
            let stateful = Stateful<Int, Int> { s in
                s += 1
                return s * 2
            }
            let publisher = Just(stateful).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let mapped = publisher.mapT { $0 + 100 }

            var capturedValue: Int?
            var capturedState: Int?
            mapped.sink(
                receiveCompletion: ignore,
                receiveValue: { stateful in
                    let (value, state) = stateful.runStateful(10)
                    capturedValue = value
                    capturedState = state
                }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 122)
            #expect(capturedState == 11)
        }

        @Test func publisherTStatefulFmapTStatic() {
            var cancellables = Set<AnyCancellable>()
            let stateful = Stateful<Int, Int> { s in
                s += 1
                return s
            }
            let publisher = Just(stateful).setFailureType(to: TestError.self).eraseToAnyPublisher()

            var capturedValue: Int?
            // Generation and application are kept in a single expression: `fmapT`'s S/Failure
            // generic parameters aren't tied to the closure, only to the publisher it's applied to.
            AnyPublisher<Stateful<Int, Int>, TestError>.fmapT { (value: Int) in value * 3 }(publisher)
                .sink(
                    receiveCompletion: ignore,
                    receiveValue: { stateful in capturedValue = stateful.eval(1) }
                )
                .store(in: &cancellables)

            #expect(capturedValue == 6)
        }

        @Test func publisherTStatefulLiftA2() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Stateful<Int, Int> { s in s + 1 }).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Stateful<Int, Int> { s in s * 2 }).setFailureType(to: TestError.self).eraseToAnyPublisher()

            var capturedValue: Int?
            // Kept as one expression: liftA2PublisherStateful's S/E parameters are only
            // pinned down once applied to pubA/pubB.
            liftA2PublisherStateful { (a: Int, b: Int) in a + b }(pubA, pubB).sink(
                receiveCompletion: ignore,
                receiveValue: { stateful in capturedValue = stateful.eval(10) }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 31) // (10 + 1) + (10 * 2)
        }

        @Test func publisherTStatefulSeqRight() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Stateful<Int, Int> { s in s + 1 }).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Stateful<Int, Int> { s in s * 2 }).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let result = seqRightPublisherStateful(pubA, pubB)

            var capturedValue: Int?
            result.sink(
                receiveCompletion: ignore,
                receiveValue: { stateful in capturedValue = stateful.eval(10) }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 20)
        }

        @Test func publisherTStatefulSeqLeft() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Stateful<Int, Int> { s in s + 1 }).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Stateful<Int, Int> { s in s * 2 }).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let result = seqLeftPublisherStateful(pubA, pubB)

            var capturedValue: Int?
            result.sink(
                receiveCompletion: ignore,
                receiveValue: { stateful in capturedValue = stateful.eval(10) }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 11)
        }

        @Test func publisherTStatefulFlatMapT() {
            var cancellables = Set<AnyCancellable>()
            let stateful = Stateful<Int, Int> { s in s + 1 }
            let publisher = Just(stateful).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let bound = publisher.flatMapT { value in
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

        @Test func publisherTStatefulBindTStatic() {
            var cancellables = Set<AnyCancellable>()
            let stateful = Stateful<Int, Int> { s in s + 1 }
            let publisher = Just(stateful).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let bindT = AnyPublisher<Stateful<Int, Int>, TestError>.bindT { (value: Int) in
                Stateful<Int, Int> { s in value + s }
            }

            var capturedValue: Int?
            bindT(publisher).sink(
                receiveCompletion: ignore,
                receiveValue: { stateful in capturedValue = stateful.eval(10) }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 21)
        }

        // MARK: - StatefulTPublisher (Stateful<S, any Publisher<A, E>>)

        @Test func statefulTPublisherMapT() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let stateful = Stateful<Int, any Publisher<Int, TestError>> { s in
                s += 1
                return Just(s).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }

            let mapped = stateful.mapT { $0 * 10 }

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

        @Test func statefulTPublisherFmapTStatic() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let stateful = Stateful<Int, any Publisher<Int, TestError>> { s in
                Just(s).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }
            let fmapT = Stateful<Int, any Publisher<Int, TestError>>.fmapT { $0 + 1 }

            var state = 5
            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            fmapT(stateful).run(&state)
                .eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 6)
        }

        @Test func statefulTPublisherApply() {
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

            let result = applyStatefulPublisher(sf, sa)

            var state = 5
            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.run(&state)
                .eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 15)
        }

        @Test func statefulTPublisherLiftA2() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let sa = Stateful<Int, any Publisher<Int, TestError>> { s in
                Just(s).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }
            // `_` is inout S — `const` takes (T) -> A not (inout T) -> A
            // swiftlint:disable:next closure_ignoring_args
            let sb = Stateful<Int, any Publisher<Int, TestError>> { _ in
                Just(100).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }

            var state = 5
            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            // Kept as one expression: liftA2StatefulPublisher's S/E parameters are only
            // pinned down once applied to sa/sb.
            liftA2StatefulPublisher { (a: Int, b: Int) in a + b }(sa, sb).run(&state)
                .eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 105)
        }

        @Test func statefulTPublisherSeqRight() {
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

            let result = seqRightStatefulPublisher(sa, sb)

            var state = 5
            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.run(&state)
                .eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 2)
        }

        @Test func statefulTPublisherSeqLeft() {
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

            let result = seqLeftStatefulPublisher(sa, sb)

            var state = 5
            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.run(&state)
                .eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 1)
        }

        // Note: StatefulTPublisher has no flatMapT/Monad — Combine's flatMap takes an
        // @escaping closure, which cannot capture an `inout` state parameter, so the
        // source (StatefulTPublisher+Monad.swift) intentionally leaves it unimplemented.

        // MARK: - PublisherTWriter (AnyPublisher<Writer<W, A>, E>)

        @Test func publisherTWriterMapT() {
            var cancellables = Set<AnyCancellable>()
            let writer = Writer<[String], Int>(5, ["created"])
            let publisher = Just(writer).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let mapped = publisher.mapT { $0 * 10 }

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

        @Test func publisherTWriterFmapTStatic() {
            var cancellables = Set<AnyCancellable>()
            let writer = Writer<[String], Int>(5, ["created"])
            let publisher = Just(writer).setFailureType(to: TestError.self).eraseToAnyPublisher()

            var capturedValue: Int?
            // Kept as one expression: `fmapT`'s W/Failure generic parameters aren't tied to
            // the closure, only to the publisher it's applied to.
            AnyPublisher<Writer<[String], Int>, TestError>.fmapT { (value: Int) in value + 1 }(publisher)
                .sink(
                    receiveCompletion: ignore,
                    receiveValue: { writer in capturedValue = writer.value }
                )
                .store(in: &cancellables)

            #expect(capturedValue == 6)
        }

        @Test func publisherTWriterLiftA2() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Writer<[String], Int>(2, ["a"])).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Writer<[String], Int>(3, ["b"])).setFailureType(to: TestError.self).eraseToAnyPublisher()

            var capturedValue: Int?
            var capturedLog: [String] = []
            // Kept as one expression: liftA2PublisherWriter's W/E parameters are only
            // pinned down once applied to pubA/pubB.
            liftA2PublisherWriter { (a: Int, b: Int) in a * b }(pubA, pubB).sink(
                receiveCompletion: ignore,
                receiveValue: { writer in
                    capturedValue = writer.value
                    capturedLog = writer.log
                }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 6)
            #expect(capturedLog == ["a", "b"])
        }

        @Test func publisherTWriterSeqRight() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Writer<[String], Int>(2, ["a"])).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Writer<[String], Int>(3, ["b"])).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let result = seqRightPublisherWriter(pubA, pubB)

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

        @Test func publisherTWriterSeqLeft() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Writer<[String], Int>(2, ["a"])).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Writer<[String], Int>(3, ["b"])).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let result = seqLeftPublisherWriter(pubA, pubB)

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

        @Test func publisherTWriterFlatMapT() {
            var cancellables = Set<AnyCancellable>()
            let writer = Writer<[String], Int>(2, ["outer"])
            let publisher = Just(writer).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let bound = publisher.flatMapT { value in
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

        @Test func publisherTWriterBindTStatic() {
            var cancellables = Set<AnyCancellable>()
            let writer = Writer<[String], Int>(2, ["outer"])
            let publisher = Just(writer).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let bindT = AnyPublisher<Writer<[String], Int>, TestError>.bindT { (value: Int) in
                Writer<[String], Int>(value + 1, ["inner"])
            }

            var capturedValue: Int?
            bindT(publisher).sink(
                receiveCompletion: ignore,
                receiveValue: { writer in capturedValue = writer.value }
            )
            .store(in: &cancellables)

            #expect(capturedValue == 3)
        }

        // MARK: - WriterTPublisher (Writer<W, any Publisher<A, E>>)

        @Test func writerTPublisherMapT() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let writer = Writer<[String], any Publisher<Int, TestError>>(
                Just(5).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["created"]
            )

            let mapped = writer.mapT { $0 * 10 }

            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            mapped.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 50)
            #expect(mapped.log == ["created"])
        }

        @Test func writerTPublisherFmapTStatic() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let writer = Writer<[String], any Publisher<Int, TestError>>(
                Just(5).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["created"]
            )
            let fmapT = Writer<[String], any Publisher<Int, TestError>>.fmapT { $0 + 1 }
            let mapped = fmapT(writer)

            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            mapped.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 6)
        }

        @Test func writerTPublisherApply() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let wf = Writer<[String], any Publisher<(Int) -> Int, TestError>>(
                Just { $0 + 1 }.setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["fn"]
            )
            let wa = Writer<[String], any Publisher<Int, TestError>>(
                Just(10).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["arg"]
            )

            let result = applyWriterPublisher(wf, wa)

            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 11)
            #expect(result.log == ["fn", "arg"])
        }

        @Test func writerTPublisherLiftA2() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let wa = Writer<[String], any Publisher<Int, TestError>>(
                Just(2).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["a"]
            )
            let wb = Writer<[String], any Publisher<Int, TestError>>(
                Just(3).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["b"]
            )

            // Kept as one expression: liftA2WriterPublisher's W/E parameters are only
            // pinned down once applied to wa/wb.
            let result = liftA2WriterPublisher { (a: Int, b: Int) in a * b }(wa, wb)

            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 6)
            #expect(result.log == ["a", "b"])
        }

        @Test func writerTPublisherSeqRight() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let lhs = Writer<[String], any Publisher<Int, TestError>>(
                Just(2).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["a"]
            )
            let rhs = Writer<[String], any Publisher<Int, TestError>>(
                Just(3).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["b"]
            )

            let result = seqRightWriterPublisher(lhs, rhs)

            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 3)
            #expect(result.log == ["a", "b"])
        }

        @Test func writerTPublisherSeqLeft() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let lhs = Writer<[String], any Publisher<Int, TestError>>(
                Just(2).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["a"]
            )
            let rhs = Writer<[String], any Publisher<Int, TestError>>(
                Just(3).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["b"]
            )

            let result = seqLeftWriterPublisher(lhs, rhs)

            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            result.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 2)
            #expect(result.log == ["a", "b"])
        }

        @Test func writerTPublisherFlatMapT() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let writer = Writer<[String], any Publisher<Int, TestError>>(
                Just(2).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["outer"]
            )

            // Outer log is kept as-is; the inner Writer's own log ("inner") is discarded
            // by design — see the doc comment in WriterTPublisher+Monad.swift.
            let bound = writer.flatMapT { value in
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

        @Test func writerTPublisherBindTStatic() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let writer = Writer<[String], any Publisher<Int, TestError>>(
                Just(2).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                ["outer"]
            )
            let bindT = Writer<[String], any Publisher<Int, TestError>>.bindT { value in
                Writer<[String], any Publisher<Int, TestError>>(
                    Just(value + 1).setFailureType(to: TestError.self).eraseToAnyPublisher(),
                    ["inner"]
                )
            }
            let bound = bindT(writer)

            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?
            bound.value.eraseToAnyPublisher()
                .sink(receiveCompletion: ignore, receiveValue: { capturedValue = $0 })
                .store(in: &cancellables)

            #expect(capturedValue == 3)
        }

        // MARK: - PublisherTEither (AnyPublisher<Either<L, A>, E>)

        @Test func publisherTEitherMapT() {
            var cancellables = Set<AnyCancellable>()
            let right: Either<String, Int> = .right(5)
            let publisher = Just(right).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let mapped = mapTPublisherEither({ $0 * 10 }, publisher)

            var captured: Either<String, Int>?
            mapped.sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .right(50))
        }

        @Test func publisherTEitherMapTLeftPassesThrough() {
            var cancellables = Set<AnyCancellable>()
            let left: Either<String, Int> = .left("boom")
            let publisher = Just(left).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let mapped = mapTPublisherEither({ $0 * 10 }, publisher)

            var captured: Either<String, Int>?
            mapped.sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .left("boom"))
        }

        @Test func publisherTEitherFmapTCurried() {
            var cancellables = Set<AnyCancellable>()
            let right: Either<String, Int> = .right(5)
            let publisher = Just(right).setFailureType(to: TestError.self).eraseToAnyPublisher()

            var captured: Either<String, Int>?
            // Kept as one expression: fmapTPublisherEither's L/E parameters are only
            // pinned down once applied to the publisher.
            fmapTPublisherEither { (value: Int) in value + 1 }(publisher).sink(
                receiveCompletion: ignore,
                receiveValue: { captured = $0 }
            )
            .store(in: &cancellables)

            #expect(captured == .right(6))
        }

        @Test func publisherTEitherLiftA2() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Either<String, Int>.right(2)).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Either<String, Int>.right(3)).setFailureType(to: TestError.self).eraseToAnyPublisher()

            // Kept as one expression: liftA2PublisherEither's L/E parameters are only
            // pinned down once applied to pubA/pubB.
            let result = liftA2PublisherEither { (a: Int, b: Int) in a + b }(pubA, pubB)

            var captured: Either<String, Int>?
            result.sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .right(5))
        }

        @Test func publisherTEitherSeqRight() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Either<String, Int>.right(2)).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Either<String, Int>.right(3)).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let result = seqRightPublisherEither(pubA, pubB)

            var captured: Either<String, Int>?
            result.sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .right(3))
        }

        @Test func publisherTEitherSeqLeft() {
            var cancellables = Set<AnyCancellable>()
            let pubA = Just(Either<String, Int>.right(2)).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let pubB = Just(Either<String, Int>.right(3)).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let result = seqLeftPublisherEither(pubA, pubB)

            var captured: Either<String, Int>?
            result.sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .right(2))
        }

        @Test func publisherTEitherFlatMapT() {
            var cancellables = Set<AnyCancellable>()
            let right: Either<String, Int> = .right(2)
            let publisher = Just(right).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let bound = flatMapTPublisherEither(publisher) { value in
                Just(Either<String, Int>.right(value * 10)).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }

            var captured: Either<String, Int>?
            bound.sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .right(20))
        }

        @Test func publisherTEitherFlatMapTLeftShortCircuits() {
            var cancellables = Set<AnyCancellable>()
            let left: Either<String, Int> = .left("boom")
            let publisher = Just(left).setFailureType(to: TestError.self).eraseToAnyPublisher()

            let bound = flatMapTPublisherEither(publisher) { value in
                Just(Either<String, Int>.right(value * 10)).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }

            var captured: Either<String, Int>?
            bound.sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .left("boom"))
        }

        @Test func publisherTEitherBindTCurried() {
            var cancellables = Set<AnyCancellable>()
            let right: Either<String, Int> = .right(2)
            let publisher = Just(right).setFailureType(to: TestError.self).eraseToAnyPublisher()
            let bindT = bindTPublisherEither { (value: Int) in
                Just(Either<String, Int>.right(value + 1)).setFailureType(to: TestError.self).eraseToAnyPublisher()
            }

            var captured: Either<String, Int>?
            bindT(publisher).sink(receiveCompletion: ignore, receiveValue: { captured = $0 })
                .store(in: &cancellables)

            #expect(captured == .right(3))
        }
    }
#endif
