// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import CoreFPOperators
    import DataStructure
    import DataStructureOperators
    import Testing

    /// Operator syntax for the Publisher stacks (ordered-concat bind, bind-derived applicative).
    @MainActor
    @Suite struct PublisherStackOperatorsTests {
        private func collect<A, E: Error>(_ publisher: any Publisher<A, E>) -> [A] {
            var results: [A] = []
            var cancellables = Set<AnyCancellable>()
            publisher.eraseToAnyPublisher()
                .sink(receiveCompletion: { _ in }, receiveValue: { results.append($0) })
                .store(in: &cancellables)
            return results
        }

        // MARK: - PublisherTEither

        private typealias EitherPub = AnyPublisher<Either<String, Int>, Never>

        private let fEither: @Sendable (Int) -> AnyPublisher<Either<String, Int>, Never> = { a in
            [Either<String, Int>.right(a), .left("f")].publisher.eraseToAnyPublisher()
        }

        private let gEither: @Sendable (Int) -> AnyPublisher<Either<String, Int>, Never> = { a in
            Just(Either<String, Int>.right(a + 1)).eraseToAnyPublisher()
        }

        private func either(_ values: [Either<String, Int>]) -> EitherPub {
            values.publisher.eraseToAnyPublisher()
        }

        @Test func publisherTEitherBindOperators() {
            #expect(collect(either([.right(1), .right(2)]) >>- fEither) == [.right(1), .left("f"), .right(2), .left("f")])
            #expect(collect(fEither -<< either([.left("m")])) == [.left("m")])
            #expect(collect((fEither >=> gEither)(1)) == [.right(2), .left("f")])
            #expect(collect((gEither <=< fEither)(1)) == [.right(2), .left("f")])
        }

        @Test func publisherTEitherApplicativeOperators() {
            let fns: [Either<String, @Sendable (Int) -> Int>] = [.right { $0 + 100 }, .left("no")]
            let fnsPublisher: AnyPublisher<Either<String, @Sendable (Int) -> Int>, Never> = fns.publisher.eraseToAnyPublisher()
            let values = either([.right(1), .right(2)])
            #expect(collect(fnsPublisher <*> values) == [.right(101), .right(102), .left("no")])
            #expect(collect(either([.right(1), .left("l")]) *> values) == [.right(1), .right(2), .left("l")])
            #expect(collect(either([.right(7), .left("l")]) <* values) == [.right(7), .right(7), .left("l")])
        }

        // MARK: - PublisherTWriter

        private typealias WriterPub = AnyPublisher<Writer<[String], Int>, Never>

        private let fWriter: @Sendable (Int) -> AnyPublisher<Writer<[String], Int>, Never> = { a in
            [Writer<[String], Int>(a, ["f1"]), Writer<[String], Int>(a * 10, ["f2"])].publisher.eraseToAnyPublisher()
        }

        private let gWriter: @Sendable (Int) -> AnyPublisher<Writer<[String], Int>, Never> = { a in
            Just(Writer<[String], Int>(a + 1, ["g"])).eraseToAnyPublisher()
        }

        private func writer(_ values: [Writer<[String], Int>]) -> WriterPub {
            values.publisher.eraseToAnyPublisher()
        }

        private func render(_ writers: [Writer<[String], Int>]) -> [String] {
            writers.map { "\($0.value)|\($0.log.joined(separator: ","))" }
        }

        @Test func publisherTWriterBindOperators() {
            let m = writer([Writer(1, ["a"]), Writer(2, ["b"])])
            #expect(render(collect(m >>- fWriter)) == ["1|a,f1", "10|a,f2", "2|b,f1", "20|b,f2"])
            #expect(render(collect(gWriter -<< m)) == ["2|a,g", "3|b,g"])
            #expect(render(collect((fWriter >=> gWriter)(1))) == ["2|f1,g", "11|f2,g"])
            #expect(render(collect((gWriter <=< fWriter)(1))) == ["2|f1,g", "11|f2,g"])
        }

        @Test func publisherTWriterApplicativeOperators() {
            let fns: [Writer<[String], @Sendable (Int) -> Int>] = [Writer({ $0 + 100 }, ["f"]), Writer({ $0 * 2 }, ["g"])]
            let fnsPublisher: AnyPublisher<Writer<[String], @Sendable (Int) -> Int>, Never> = fns.publisher.eraseToAnyPublisher()
            let lhs = writer([Writer(1, ["a"]), Writer(2, ["b"])])
            let rhs = writer([Writer(10, ["x"]), Writer(20, ["y"])])
            #expect(render(collect(fnsPublisher <*> rhs)) == ["110|f,x", "120|f,y", "20|g,x", "40|g,y"])
            #expect(render(collect(lhs *> rhs)) == ["10|a,x", "20|a,y", "10|b,x", "20|b,y"])
            #expect(render(collect(lhs <* rhs)) == ["1|a,x", "1|a,y", "2|b,x", "2|b,y"])
        }

        // MARK: - ReaderTPublisher

        private typealias ReaderPub = Reader<Int, any Publisher<Int, Never>>

        @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
        private typealias ReaderPubT = ReaderTPublisher<Int, Never, Int>

        @Test func readerTPublisherBindOperators() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let m = ReaderPubT(ReaderPub { env in [1, env].publisher })
            let f: @Sendable (Int) -> ReaderPubT = { a in ReaderPubT(Reader { env in [a, a * env].publisher }) }
            let g: @Sendable (Int) -> ReaderPubT = { a in ReaderPubT(Reader { env in Just(a + env) }) }
            #expect(collect((m >>- f).rawValue(3)) == [1, 3, 3, 9])
            #expect(collect((g -<< m).rawValue(3)) == [4, 6])
            #expect(collect((f >=> g)(2).rawValue(3)) == [5, 9])
            #expect(collect((g <=< f)(2).rawValue(3)) == [5, 9])
        }

        @Test func readerTPublisherFunctorOperators() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let m = ReaderPubT(ReaderPub { env in [1, env].publisher })
            #expect(collect(({ $0 * 2 } <£> m).rawValue(3)) == [2, 6])
            #expect(collect((m <&> { $0 + 1 }).rawValue(3)) == [2, 4])
            #expect(collect((m £> 0).rawValue(3)) == [0, 0])
            #expect(collect((0 <£ m).rawValue(3)) == [0, 0])
        }

        @Test func readerTPublisherApplicativeOperators() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let fns = ReaderTPublisher(Reader<Int, any Publisher<@Sendable (Int) -> Int, Never>> { env in
                [{ $0 + env }, { $0 * env }].publisher
            })
            let lhs = ReaderPubT(ReaderPub { env in [env, env + 1].publisher })
            let rhs = ReaderPubT(ReaderPub { env in [env * 10, env * 20].publisher })
            #expect(collect((fns <*> rhs).rawValue(1)) == [11, 21, 10, 20])
            #expect(collect((lhs *> rhs).rawValue(1)) == [10, 20, 10, 20])
            #expect(collect((lhs <* rhs).rawValue(1)) == [1, 1, 2, 2])
        }
    }
#endif
