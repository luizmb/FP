// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    @testable import DataStructure
    import Testing

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    private func fReader(_ a: Int) -> ReaderTPublisher<Int, Never, Int> {
        ReaderTPublisher(Reader { env in [a, a * env].publisher })
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    private func gReader(_ a: Int) -> ReaderTPublisher<Int, Never, Int> {
        ReaderTPublisher(Reader { env in Just(a + env) })
    }

    /// Publisher stacks (PublisherTEither, PublisherTWriter, ReaderTPublisher) use the Publisher
    /// ordered-concat bind, and their applicatives are the bind-derived `ap`.
    @MainActor
    @Suite struct PublisherStackLawTests {
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

        private func eitherPublisher(_ values: [Either<String, Int>]) -> EitherPub {
            values.publisher.eraseToAnyPublisher()
        }

        @Test func publisherTEitherMonadLaws() {
            let fEither: @Sendable (Int) -> EitherPub = { a in
                [Either<String, Int>.right(a), .left("f"), .right(a * 10)].publisher.eraseToAnyPublisher()
            }
            let gEither: @Sendable (Int) -> EitherPub = { a in Just(.right(a + 1)).eraseToAnyPublisher() }
            let pureEither: @Sendable (Int) -> EitherPub = { a in Just(.right(a)).eraseToAnyPublisher() }
            let values: [Either<String, Int>] = [.right(1), .left("m"), .right(2)]
            let m = eitherPublisher(values)

            #expect(collect(flatMapTPublisherEither(pureEither(4), fEither)) == collect(fEither(4)))
            #expect(collect(flatMapTPublisherEither(m, pureEither)) == values)
            let lhs = flatMapTPublisherEither(flatMapTPublisherEither(m, fEither), gEither)
            let rhs = flatMapTPublisherEither(m, kleisliT(fEither, gEither))
            #expect(collect(lhs) == collect(rhs))
            #expect(collect(lhs) == [.right(2), .left("f"), .right(11), .left("m"), .right(3), .left("f"), .right(21)])
        }

        @Test func publisherTEitherApEqualsBindDerived() {
            let fns: [Either<String, @Sendable (Int) -> Int>] = [.right { $0 + 100 }, .left("no"), .right { $0 * 2 }]
            let values: [Either<String, Int>] = [.right(1), .right(2)]
            let fnsPublisher: AnyPublisher<Either<String, @Sendable (Int) -> Int>, Never> = fns.publisher.eraseToAnyPublisher()
            let applied = applyPublisherEither(fnsPublisher, eitherPublisher(values))
            let ap = flatMapTPublisherEither(fnsPublisher) { fn in
                values.publisher.eraseToAnyPublisher().mapT(fn)
            }
            #expect(collect(applied) == collect(ap))
            #expect(collect(applied) == [.right(101), .right(102), .left("no"), .right(2), .right(4)])
        }

        @Test func publisherTEitherSeqAndLiftA2() {
            let lhs = eitherPublisher([.right(1), .left("l")])
            let rhs = eitherPublisher([.right(10), .right(20)])
            #expect(collect(seqRightPublisherEither(lhs, rhs)) == [.right(10), .right(20), .left("l")])
            #expect(collect(seqLeftPublisherEither(lhs, rhs)) == [.right(1), .right(1), .left("l")])
            let lifted = liftA2PublisherEither { (a: Int, b: Int) in a + b }(lhs, rhs)
            #expect(collect(lifted) == [.right(11), .right(21), .left("l")])
        }

        // MARK: - PublisherTWriter

        private typealias WriterPub = AnyPublisher<Writer<[String], Int>, Never>

        private func render(_ writers: [Writer<[String], Int>]) -> [String] {
            writers.map { "\($0.value)|\($0.log.joined(separator: ","))" }
        }

        private func writerPublisher(_ values: [Writer<[String], Int>]) -> WriterPub {
            values.publisher.eraseToAnyPublisher()
        }

        private let fWriter: @Sendable (Int) -> AnyPublisher<Writer<[String], Int>, Never> = { a in
            [Writer<[String], Int>(a, ["f1"]), Writer<[String], Int>(a * 10, ["f2"])].publisher.eraseToAnyPublisher()
        }

        private let gWriter: @Sendable (Int) -> AnyPublisher<Writer<[String], Int>, Never> = { a in
            Just(Writer<[String], Int>(a + 1, ["g"])).eraseToAnyPublisher()
        }

        private let pureWriter: @Sendable (Int) -> AnyPublisher<Writer<[String], Int>, Never> = { a in
            Just(Writer<[String], Int>(a, [])).eraseToAnyPublisher()
        }

        @Test func publisherTWriterLeftIdentity() {
            #expect(render(collect(pureWriter(3).flatMapT(fWriter))) == render(collect(fWriter(3))))
        }

        @Test func publisherTWriterRightIdentity() {
            let m = writerPublisher([Writer(1, ["a"]), Writer(2, ["b"])])
            #expect(render(collect(m.flatMapT(pureWriter))) == ["1|a", "2|b"])
        }

        @Test func publisherTWriterAssociativity() {
            let m = writerPublisher([Writer(1, ["a"]), Writer(2, ["b"])])
            let lhs = m.flatMapT(fWriter).flatMapT(gWriter)
            let rhs = m.flatMapT(kleisliT(fWriter, gWriter))
            #expect(render(collect(lhs)) == render(collect(rhs)))
            #expect(render(collect(lhs)) == ["2|a,f1,g", "11|a,f2,g", "3|b,f1,g", "21|b,f2,g"])
        }

        @Test func publisherTWriterBindTMatchesFlatMapT() {
            let m = writerPublisher([Writer(1, ["a"])])
            let bound = AnyPublisher<Writer<[String], Int>, Never>.bindT(fWriter)(m)
            #expect(render(collect(bound)) == render(collect(m.flatMapT(fWriter))))
        }

        @Test func publisherTWriterApEqualsBindDerived() {
            let fns: [Writer<[String], @Sendable (Int) -> Int>] = [Writer({ $0 + 100 }, ["f"]), Writer({ $0 * 2 }, ["g"])]
            let values: [Writer<[String], Int>] = [Writer(1, ["x"]), Writer(2, ["y"])]
            let fnsPublisher: AnyPublisher<Writer<[String], @Sendable (Int) -> Int>, Never> = fns.publisher.eraseToAnyPublisher()
            let applied = applyPublisherWriter(fnsPublisher, writerPublisher(values))
            let ap = fnsPublisher.flatMapT { fn in
                values.publisher.eraseToAnyPublisher().mapT(fn)
            }
            #expect(render(collect(applied)) == render(collect(ap)))
            #expect(render(collect(applied)) == ["101|f,x", "102|f,y", "2|g,x", "4|g,y"])
        }

        @Test func publisherTWriterSeqAndLiftA2() {
            let lhs = writerPublisher([Writer(1, ["a"]), Writer(2, ["b"])])
            let rhs = writerPublisher([Writer(10, ["x"]), Writer(20, ["y"])])
            #expect(render(collect(seqRightPublisherWriter(lhs, rhs))) == ["10|a,x", "20|a,y", "10|b,x", "20|b,y"])
            #expect(render(collect(seqLeftPublisherWriter(lhs, rhs))) == ["1|a,x", "1|a,y", "2|b,x", "2|b,y"])
            let lifted = liftA2PublisherWriter { (a: Int, b: Int) in a + b }(lhs, rhs)
            #expect(render(collect(lifted)) == ["11|a,x", "21|a,y", "12|b,x", "22|b,y"])
        }

        // MARK: - ReaderTPublisher

        private typealias ReaderPub = Reader<Int, any Publisher<Int, Never>>

        @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
        private typealias ReaderPubT = ReaderTPublisher<Int, Never, Int>

        @Test func readerTPublisherLeftIdentity() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            #expect(collect(ReaderPubT.pure(3).flatMap(fReader).rawValue(10)) == collect(fReader(3).rawValue(10)))
        }

        @Test func readerTPublisherRightIdentity() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let m = ReaderPubT(ReaderPub { env in [env, env + 1].publisher })
            #expect(collect(m.flatMap(ReaderPubT.pure).rawValue(10)) == [10, 11])
        }

        @Test func readerTPublisherAssociativityIsOrderedConcat() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let m = ReaderPubT(ReaderPub { env in [1, 2].publisher.map { $0 * env } })
            let lhs = m.flatMap(fReader).flatMap(gReader)
            let rhs = m.flatMap(ReaderPubT.kleisli(fReader, gReader))
            #expect(collect(lhs.rawValue(2)) == collect(rhs.rawValue(2)))
            // m(2) = [2, 4]; f 2 = [2, 4]; f 4 = [4, 8]; g adds env
            #expect(collect(lhs.rawValue(2)) == [4, 6, 6, 10])
        }

        @Test func readerTPublisherApEqualsBindDerived() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let fns = ReaderTPublisher(Reader<Int, any Publisher<@Sendable (Int) -> Int, Never>> { env in
                [{ $0 + env }, { $0 * env }].publisher
            })
            let values = ReaderPubT(ReaderPub { env in [1, env].publisher })
            let applied = ReaderPubT.apply(fns, values)
            let ap = fns.flatMap { fn in values.map(fn) }
            #expect(collect(applied.rawValue(10)) == collect(ap.rawValue(10)))
            #expect(collect(applied.rawValue(10)) == [11, 20, 10, 100])
        }

        @Test func readerTPublisherSeqAndLiftA2() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let lhs = ReaderPubT(ReaderPub { env in [env, env + 1].publisher })
            let rhs = ReaderPubT(ReaderPub { env in [env * 10, env * 20].publisher })
            #expect(collect(lhs.seqRight(rhs).rawValue(1)) == [10, 20, 10, 20])
            #expect(collect(lhs.seqLeft(rhs).rawValue(1)) == [1, 1, 2, 2])
            let lifted = ReaderPubT.liftA2 { (a: Int, b: Int) in a + b }(lhs, rhs)
            #expect(collect(lifted.rawValue(1)) == [11, 21, 12, 22])
        }
    }
#endif
