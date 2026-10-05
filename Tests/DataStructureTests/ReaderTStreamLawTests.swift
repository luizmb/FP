// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// Functor, applicative and monad laws for the stream-inner Reader stacks (`ReaderTAsyncStream`,
// `ReaderTPublisher`), on the struct API. Each side of a law is built fresh for every run (streams are
// single-pass) and compared by collecting the emitted elements.

private let streamIncrement: @Sendable (Int) -> Int = { $0 + 1 }
private let streamDescribe: @Sendable (Int) -> String = { "<\($0)>" }

// MARK: - ReaderTAsyncStream

typealias LawRStream<A> = ReaderTAsyncStream<Int, A>

private func expectSameStream<A: Equatable & Sendable>(
    _ lhs: @Sendable () -> LawRStream<A>,
    _ rhs: @Sendable () -> LawRStream<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    for env in readerTLawEnvironments {
        let lhsValues = await collectAll(lhs().rawValue(env))
        let rhsValues = await collectAll(rhs().rawValue(env))
        #expect(lhsValues == rhsValues, sourceLocation: sourceLocation)
    }
}

@Suite struct ReaderTAsyncStreamLawTests {
    let ms: [@Sendable () -> LawRStream<Int>] = [
        { LawRStream<Int>(Reader { streamOf([$0, $0 + 1]) }) },
        { LawRStream<Int>(Reader(const(streamOf([])))) }
    ]
    let f: @Sendable (Int) -> LawRStream<Int> = { a in LawRStream<Int>(Reader { env in streamOf([a, a * env]) }) }
    let g: @Sendable (Int) -> LawRStream<String> = { b in LawRStream<String>(Reader { env in streamOf(["\(b + env)"]) }) }

    @Test func functorIdentity() async {
        for m in ms {
            await expectSameStream({ m().map(id) }, m)
        }
    }

    @Test func functorComposition() async {
        for m in ms {
            await expectSameStream({ m().map(streamIncrement).map(streamDescribe) }, { m().map { streamDescribe(streamIncrement($0)) } })
        }
    }

    @Test func applyEqualsAp() async {
        let fs: @Sendable () -> LawRStream<@Sendable (Int) -> Int> = {
            LawRStream(Reader { env in streamOf([{ $0 + env }, { $0 * 2 }]) })
        }
        for m in ms {
            await expectSameStream({ LawRStream<Int>.apply(fs(), m()) }, { fs().flatMap { fn in m().map(fn) } })
        }
    }

    @Test func leftIdentity() async {
        let f = f
        for a in [0, 1, 7] {
            await expectSameStream({ LawRStream<Int>.pure(a).flatMap(f) }, { f(a) })
        }
    }

    @Test func rightIdentity() async {
        for m in ms {
            await expectSameStream({ m().flatMap(LawRStream<Int>.pure) }, m)
        }
    }

    @Test func associativity() async {
        let f = f
        let g = g
        for m in ms {
            await expectSameStream({ m().flatMap(f).flatMap(g) }, { m().flatMap { a in f(a).flatMap(g) } })
        }
    }

    @Test func escapeHatchReachesTheWholeReader() async {
        for m in ms {
            await expectSameStream(
                { m().mapReaderT { $0.local(streamIncrement) } },
                { LawRStream<Int>(Reader { m().rawValue(streamIncrement($0)) }) }
            )
        }
    }

    @Test func liftingPropertyWrapsTheNestedValue() async {
        let nested: @Sendable () -> Reader<Int, AsyncStream<Int>> = { Reader { streamOf([$0, $0 * 2]) } }
        await expectSameStream({ nested().readerT }, { LawRStream<Int>(nested()) })
    }
}

#if canImport(Combine)
    import Combine

    // MARK: - ReaderTPublisher

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    typealias LawRPublisher<A> = ReaderTPublisher<Int, Never, A>

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    private func lawPublisherF(_ a: Int) -> LawRPublisher<Int> {
        LawRPublisher<Int>(Reader { env in [a, a * env].publisher })
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    private func lawPublisherG(_ b: Int) -> LawRPublisher<String> {
        LawRPublisher<String>(Reader { env in Just("\(b + env)") })
    }

    @MainActor
    @Suite struct ReaderTPublisherLawTests {
        private func collect<A>(_ publisher: any Publisher<A, Never>) -> [A] {
            var results: [A] = []
            var cancellables = Set<AnyCancellable>()
            publisher.eraseToAnyPublisher()
                .sink { results.append($0) }
                .store(in: &cancellables)
            return results
        }

        @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
        private func expectSame<A: Equatable>(
            _ lhs: LawRPublisher<A>,
            _ rhs: LawRPublisher<A>,
            sourceLocation: SourceLocation = #_sourceLocation
        ) {
            for env in readerTLawEnvironments {
                #expect(collect(lhs.rawValue(env)) == collect(rhs.rawValue(env)), sourceLocation: sourceLocation)
            }
        }

        @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
        private var ms: [LawRPublisher<Int>] {
            [
                LawRPublisher<Int>(Reader { [$0, $0 + 1].publisher }),
                LawRPublisher<Int>(Reader { [$0].publisher.dropFirst() })
            ]
        }

        @Test func functorIdentity() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            for m in ms {
                expectSame(m.map(id), m)
            }
        }

        @Test func functorComposition() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            for m in ms {
                expectSame(m.map(streamIncrement).map(streamDescribe), m.map { streamDescribe(streamIncrement($0)) })
            }
        }

        @Test func applyEqualsAp() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let fs = LawRPublisher<@Sendable (Int) -> Int>(Reader { env in [{ $0 + env }, { $0 * 2 }].publisher })
            for m in ms {
                expectSame(LawRPublisher<Int>.apply(fs, m), fs.flatMap { fn in m.map(fn) })
            }
        }

        @Test func leftIdentity() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            for a in [0, 1, 7] {
                expectSame(LawRPublisher<Int>.pure(a).flatMap(lawPublisherF), lawPublisherF(a))
            }
        }

        @Test func rightIdentity() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            for m in ms {
                expectSame(m.flatMap(LawRPublisher<Int>.pure), m)
            }
        }

        @Test func associativity() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            for m in ms {
                expectSame(m.flatMap(lawPublisherF).flatMap(lawPublisherG), m.flatMap { a in lawPublisherF(a).flatMap(lawPublisherG) })
            }
        }

        @Test func escapeHatchReachesTheWholeReader() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            for m in ms {
                expectSame(m.mapReaderT { $0.local(streamIncrement) }, LawRPublisher<Int>(Reader { m.rawValue(streamIncrement($0)) }))
            }
        }

        @Test func liftingPropertyWrapsTheNestedValue() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let nested = Reader<Int, Publishers.Sequence<[Int], Never>> { [$0, $0 * 2].publisher }
            expectSame(nested.readerT, LawRPublisher<Int>(nested.mapReader { $0 }))
        }
    }
#endif
