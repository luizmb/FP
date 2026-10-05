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

        private typealias EitherPub = PublisherTEither<Never, String, Int>

        private func eitherPublisher(_ values: [Either<String, Int>]) -> EitherPub {
            values.publisher.publisherT
        }

        @Test func publisherTEitherMonadLaws() {
            let fEither: @Sendable (Int) -> EitherPub = { a in
                [Either<String, Int>.right(a), .left("f"), .right(a * 10)].publisher.publisherT
            }
            let gEither: @Sendable (Int) -> EitherPub = { a in Just(Either<String, Int>.right(a + 1)).publisherT }
            let values: [Either<String, Int>] = [.right(1), .left("m"), .right(2)]
            let m = eitherPublisher(values)

            #expect(collect(EitherPub.pure(4).flatMap(fEither).rawValue) == collect(fEither(4).rawValue))
            #expect(collect(m.flatMap(EitherPub.pure).rawValue) == values)
            let lhs = m.flatMap(fEither).flatMap(gEither)
            let rhs = m.flatMap(EitherPub.kleisli(fEither, gEither))
            #expect(collect(lhs.rawValue) == collect(rhs.rawValue))
            #expect(collect(lhs.rawValue) == [.right(2), .left("f"), .right(11), .left("m"), .right(3), .left("f"), .right(21)])
        }

        @Test func publisherTEitherApEqualsBindDerived() {
            let fns: [Either<String, @Sendable (Int) -> Int>] = [.right { $0 + 100 }, .left("no"), .right { $0 * 2 }]
            let values: [Either<String, Int>] = [.right(1), .right(2)]
            let fnsPublisher = fns.publisher.publisherT
            let applied = PublisherTEither.apply(fnsPublisher, eitherPublisher(values))
            let ap = fnsPublisher.flatMap { fn in
                values.publisher.publisherT.map(fn)
            }
            #expect(collect(applied.rawValue) == collect(ap.rawValue))
            #expect(collect(applied.rawValue) == [.right(101), .right(102), .left("no"), .right(2), .right(4)])
        }

        @Test func publisherTEitherSeqAndLiftA2() {
            let lhs = eitherPublisher([.right(1), .left("l")])
            let rhs = eitherPublisher([.right(10), .right(20)])
            #expect(collect(lhs.seqRight(rhs).rawValue) == [.right(10), .right(20), .left("l")])
            #expect(collect(lhs.seqLeft(rhs).rawValue) == [.right(1), .right(1), .left("l")])
            let lifted = EitherPub.liftA2 { (a: Int, b: Int) in a + b }(lhs, rhs)
            #expect(collect(lifted.rawValue) == [.right(11), .right(21), .left("l")])
        }

        // MARK: - PublisherTWriter

        private typealias WriterPub = PublisherTWriter<Never, [String], Int>

        private func render(_ writers: [Writer<[String], Int>]) -> [String] {
            writers.map { "\($0.value)|\($0.log.joined(separator: ","))" }
        }

        private func writerPublisher(_ values: [Writer<[String], Int>]) -> WriterPub {
            values.publisher.publisherT
        }

        private let fWriter: @Sendable (Int) -> PublisherTWriter<Never, [String], Int> = { a in
            [Writer<[String], Int>(a, ["f1"]), Writer<[String], Int>(a * 10, ["f2"])].publisher.publisherT
        }

        private let gWriter: @Sendable (Int) -> PublisherTWriter<Never, [String], Int> = { a in
            Just(Writer<[String], Int>(a + 1, ["g"])).publisherT
        }

        @Test func publisherTWriterLeftIdentity() {
            #expect(render(collect(WriterPub.pure(3).flatMap(fWriter).rawValue)) == render(collect(fWriter(3).rawValue)))
        }

        @Test func publisherTWriterRightIdentity() {
            let m = writerPublisher([Writer(1, ["a"]), Writer(2, ["b"])])
            #expect(render(collect(m.flatMap(WriterPub.pure).rawValue)) == ["1|a", "2|b"])
        }

        @Test func publisherTWriterAssociativity() {
            let m = writerPublisher([Writer(1, ["a"]), Writer(2, ["b"])])
            let lhs = m.flatMap(fWriter).flatMap(gWriter)
            let rhs = m.flatMap(WriterPub.kleisli(fWriter, gWriter))
            #expect(render(collect(lhs.rawValue)) == render(collect(rhs.rawValue)))
            #expect(render(collect(lhs.rawValue)) == ["2|a,f1,g", "11|a,f2,g", "3|b,f1,g", "21|b,f2,g"])
        }

        @Test func publisherTWriterBindMatchesFlatMap() {
            let m = writerPublisher([Writer(1, ["a"])])
            let bound = WriterPub.bind(fWriter)(m)
            #expect(render(collect(bound.rawValue)) == render(collect(m.flatMap(fWriter).rawValue)))
        }

        @Test func publisherTWriterApEqualsBindDerived() {
            let fns: [Writer<[String], @Sendable (Int) -> Int>] = [Writer({ $0 + 100 }, ["f"]), Writer({ $0 * 2 }, ["g"])]
            let values: [Writer<[String], Int>] = [Writer(1, ["x"]), Writer(2, ["y"])]
            let fnsPublisher = fns.publisher.publisherT
            let applied = PublisherTWriter.apply(fnsPublisher, writerPublisher(values))
            let ap = fnsPublisher.flatMap { fn in
                values.publisher.publisherT.map(fn)
            }
            #expect(render(collect(applied.rawValue)) == render(collect(ap.rawValue)))
            #expect(render(collect(applied.rawValue)) == ["101|f,x", "102|f,y", "2|g,x", "4|g,y"])
        }

        @Test func publisherTWriterSeqAndLiftA2() {
            let lhs = writerPublisher([Writer(1, ["a"]), Writer(2, ["b"])])
            let rhs = writerPublisher([Writer(10, ["x"]), Writer(20, ["y"])])
            #expect(render(collect(lhs.seqRight(rhs).rawValue)) == ["10|a,x", "20|a,y", "10|b,x", "20|b,y"])
            #expect(render(collect(lhs.seqLeft(rhs).rawValue)) == ["1|a,x", "1|a,y", "2|b,x", "2|b,y"])
            let lifted = WriterPub.liftA2 { (a: Int, b: Int) in a + b }(lhs, rhs)
            #expect(render(collect(lifted.rawValue)) == ["11|a,x", "21|a,y", "12|b,x", "22|b,y"])
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
