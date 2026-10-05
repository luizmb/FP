// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import CoreFPOperators
    import DataStructure
    import DataStructureOperators
    import Testing

    @MainActor
    @Suite struct ReaderCombineOperatorsTests {
        struct Environment {
            let multiplier: Int
        }

        enum TestError: Error {
            case test
        }

        // MARK: - Applicative Operators

        @Test func applicativeOperatorApply() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let readerFn = Reader<Environment, any Publisher<@Sendable (Int) -> Int, TestError>> { env in
                let multiplier = env.multiplier
                return Just<@Sendable (Int) -> Int> { $0 + multiplier }
                    .setFailureType(to: TestError.self)
                    .eraseToAnyPublisher()
            }

            // swiftlint:disable:next closure_ignoring_args
            let readerValue = Reader<Environment, any Publisher<Int, TestError>> { _ in
                Just(10)
                    .setFailureType(to: TestError.self)
                    .eraseToAnyPublisher()
            }

            let result = (ReaderTPublisher(readerFn) <*> ReaderTPublisher(readerValue)).rawValue

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

            let bound = (ReaderTPublisher(reader) >>- { value in
                ReaderTPublisher(Reader<Environment, any Publisher<String, TestError>> { env in
                    Just("\(value + env.multiplier)")
                        .setFailureType(to: TestError.self)
                        .eraseToAnyPublisher()
                })
            }).rawValue

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

            let fn: @Sendable (Int) -> ReaderTPublisher<Environment, TestError, String> = { value in
                ReaderTPublisher(Reader { env in
                    Just("\(value + env.multiplier)")
                        .setFailureType(to: TestError.self)
                        .eraseToAnyPublisher()
                })
            }

            let bound = (fn -<< ReaderTPublisher(reader)).rawValue

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
            let parse: @Sendable (String) -> ReaderTPublisher<Environment, TestError, Int> = { s in
                // swiftlint:disable:next closure_ignoring_args
                ReaderTPublisher(Reader { _ in
                    Just(Int(s) ?? 0)
                        .setFailureType(to: TestError.self)
                        .eraseToAnyPublisher()
                })
            }

            let scale: @Sendable (Int) -> ReaderTPublisher<Environment, TestError, Int> = { n in
                ReaderTPublisher(Reader { env in
                    Just(n * env.multiplier)
                        .setFailureType(to: TestError.self)
                        .eraseToAnyPublisher()
                })
            }

            let pipeline = parse >=> scale

            let env = Environment(multiplier: 3)
            var cancellables = Set<AnyCancellable>()
            var capturedValue: Int?

            pipeline("7").rawValue(env)
                .sink(
                    receiveCompletion: ignore,
                    receiveValue: { value in capturedValue = value }
                )
                .store(in: &cancellables)

            #expect(capturedValue == 21)
        }
    }
#endif
