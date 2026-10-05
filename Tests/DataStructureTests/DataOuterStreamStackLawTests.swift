// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// Laws for the stream-outer newtype stacks (AsyncStream / Publisher over Either, Writer, Stateful), on the struct API.
// Streams are single-pass, so every sample is rebuilt from a factory before each observation.

private let inc: @Sendable (Int) -> Int = { $0 + 1 }
private let dbl: @Sendable (Int) -> Int = { $0 * 2 }

private let tick = Stateful<Int, Int> { state in
    state += 1
    return state * 10
}

private func runAt1(_ stateful: Stateful<Int, Int>) -> [Int] {
    [stateful.eval(1), stateful.exec(1)]
}

@Suite struct DataOuterStreamStackLawTests {
    // MARK: - AsyncStreamTEither

    @Test func asyncStreamTEitherLaws() async {
        typealias Stack = AsyncStreamTEither<String, Int>
        let values: [Either<String, Int>] = [.right(1), .left("e"), .right(2)]
        let make: @Sendable () -> Stack = { Stack(streamOf(values)) }
        let f: @Sendable (Int) -> Stack = { Stack(streamOf([.right($0), .left("f")])) }
        let g: @Sendable (Int) -> Stack = { Stack(streamOf([.right($0 + 1)])) }
        let fns: @Sendable () -> AsyncStreamTEither<String, @Sendable (Int) -> Int> = {
            AsyncStreamTEither(streamOf([.right(inc), .left("nf"), .right(dbl)]))
        }

        let lifted = await collectAll(streamOf(values).asyncStreamT.rawValue)
        let escapedStack: Stack = make().mapAsyncStreamT(const(streamOf([Stack.I.left("gone")])))
        let escaped = await collectAll(escapedStack.rawValue)
        #expect(lifted == values)
        #expect(escaped == [.left("gone")])
        // Functor
        let identity = await collectAll(make().map(CoreFP.id).rawValue)
        let composedMaps = await collectAll(make().map(inc).map(dbl).rawValue)
        let mapOfComposed = await collectAll(make().map { dbl(inc($0)) }.rawValue)
        #expect(identity == values)
        #expect(composedMaps == mapOfComposed)
        // <*> == ap
        let applied = await collectAll(Stack.apply(fns(), make()).rawValue)
        let derived = await collectAll(fns().flatMap { fn in make().map(fn) }.rawValue)
        #expect(applied == derived)
        // Monad
        let leftIdentity = await collectAll(Stack.pure(3).flatMap(f).rawValue)
        let fAt3 = await collectAll(f(3).rawValue)
        let rightIdentity = await collectAll(make().flatMap(Stack.pure).rawValue)
        let lhs = await collectAll(make().flatMap(f).flatMap(g).rawValue)
        let rhs = await collectAll(make().flatMap(Stack.kleisli(f, g)).rawValue)
        #expect(leftIdentity == fAt3)
        #expect(rightIdentity == values)
        #expect(lhs == rhs)
    }

    // MARK: - AsyncStreamTWriter

    @Test func asyncStreamTWriterLaws() async {
        typealias Stack = AsyncStreamTWriter<[String], Int>
        let values = [Writer(1, ["a"]), Writer(2, ["b"])]
        let make: @Sendable () -> Stack = { Stack(streamOf(values)) }
        let f: @Sendable (Int) -> Stack = { Stack(streamOf([Writer($0, ["f"]), Writer($0 + 1, ["f'"])])) }
        let g: @Sendable (Int) -> Stack = { Stack(streamOf([Writer($0 * 10, ["g"])])) }
        let fns: @Sendable () -> AsyncStreamTWriter<[String], @Sendable (Int) -> Int> = {
            AsyncStreamTWriter(streamOf([Writer(inc, ["inc"]), Writer(dbl, ["dbl"])]))
        }

        let lifted = await collectAll(streamOf(values).asyncStreamT.rawValue)
        let escapedStack: Stack = make().mapAsyncStreamT(const(streamOf([Writer(0, ["gone"])])))
        let escaped = await collectAll(escapedStack.rawValue)
        #expect(lifted == values)
        #expect(escaped == [Writer(0, ["gone"])])
        // Functor
        let identity = await collectAll(make().map(CoreFP.id).rawValue)
        let composedMaps = await collectAll(make().map(inc).map(dbl).rawValue)
        let mapOfComposed = await collectAll(make().map { dbl(inc($0)) }.rawValue)
        #expect(identity == values)
        #expect(composedMaps == mapOfComposed)
        // <*> == ap
        let applied = await collectAll(Stack.apply(fns(), make()).rawValue)
        let derived = await collectAll(fns().flatMap { fn in make().map(fn) }.rawValue)
        #expect(applied == derived)
        // Monad
        let leftIdentity = await collectAll(Stack.pure(3).flatMap(f).rawValue)
        let fAt3 = await collectAll(f(3).rawValue)
        let rightIdentity = await collectAll(make().flatMap(Stack.pure).rawValue)
        let lhs = await collectAll(make().flatMap(f).flatMap(g).rawValue)
        let rhs = await collectAll(make().flatMap(Stack.kleisli(f, g)).rawValue)
        #expect(leftIdentity == fAt3)
        #expect(rightIdentity == values)
        #expect(lhs == rhs)
    }

    // MARK: - AsyncStreamTStateful (functor only)

    @Test func asyncStreamTStatefulLaws() async {
        typealias Stack = AsyncStreamTStateful<Int, Int>
        let make: @Sendable () -> Stack = { streamOf([tick, Stateful<Int, Int>.pure(7)]).asyncStreamT }
        let observe: @Sendable (Stack) async -> [[Int]] = { await collectAll($0.rawValue).map(runAt1) }

        let initial = await observe(make())
        let escapedStack: Stack = make().mapAsyncStreamT(const(streamOf([tick])))
        let escaped = await observe(escapedStack)
        let identity = await observe(make().map(CoreFP.id))
        let composedMaps = await observe(make().map(inc).map(dbl))
        let mapOfComposed = await observe(make().map { dbl(inc($0)) })
        #expect(initial == [[20, 2], [7, 1]])
        #expect(escaped == [[20, 2]])
        #expect(identity == initial)
        #expect(composedMaps == mapOfComposed)
    }
}

#if canImport(Combine)
    import Combine

    @MainActor
    @Suite struct DataOuterPublisherStackLawTests {
        private func collect<A, E: Error>(_ publisher: AnyPublisher<A, E>) -> [A] {
            var results: [A] = []
            var cancellables = Set<AnyCancellable>()
            publisher
                .sink(receiveCompletion: { _ in }, receiveValue: { results.append($0) })
                .store(in: &cancellables)
            return results
        }

        // MARK: - PublisherTEither

        @Test func publisherTEitherLaws() {
            typealias Stack = PublisherTEither<Never, String, Int>
            let values: [Either<String, Int>] = [.right(1), .left("e"), .right(2)]
            let make: @Sendable () -> Stack = { values.publisher.eraseToAnyPublisher().publisherT }
            let f: @Sendable (Int) -> Stack = { Stack([Either<String, Int>.right($0), .left("f")].publisher.eraseToAnyPublisher()) }
            let g: @Sendable (Int) -> Stack = { Stack(Just(Either<String, Int>.right($0 + 1)).eraseToAnyPublisher()) }
            let fnValues: [Either<String, @Sendable (Int) -> Int>] = [.right(inc), .left("nf"), .right(dbl)]
            let fns: @Sendable () -> PublisherTEither<Never, String, @Sendable (Int) -> Int> = {
                PublisherTEither(fnValues.publisher.eraseToAnyPublisher())
            }

            #expect(collect(make().rawValue) == values)
            let escaped: Stack = make().mapPublisherT { $0.prefix(1).eraseToAnyPublisher() }
            #expect(collect(escaped.rawValue) == [.right(1)])
            #expect(collect(make().map(CoreFP.id).rawValue) == values)
            #expect(collect(make().map(inc).map(dbl).rawValue) == collect(make().map { dbl(inc($0)) }.rawValue))
            #expect(collect(Stack.apply(fns(), make()).rawValue) == collect(fns().flatMap { fn in make().map(fn) }.rawValue))
            #expect(collect(Stack.pure(3).flatMap(f).rawValue) == collect(f(3).rawValue))
            #expect(collect(make().flatMap(Stack.pure).rawValue) == values)
            #expect(collect(make().flatMap(f).flatMap(g).rawValue) == collect(make().flatMap(Stack.kleisli(f, g)).rawValue))
        }

        // MARK: - PublisherTWriter

        @Test func publisherTWriterLaws() {
            typealias Stack = PublisherTWriter<Never, [String], Int>
            let values = [Writer(1, ["a"]), Writer(2, ["b"])]
            let make: @Sendable () -> Stack = { values.publisher.eraseToAnyPublisher().publisherT }
            let f: @Sendable (Int) -> Stack = { Stack([Writer($0, ["f"]), Writer($0 + 1, ["f'"])].publisher.eraseToAnyPublisher()) }
            let g: @Sendable (Int) -> Stack = { Stack(Just(Writer($0 * 10, ["g"])).eraseToAnyPublisher()) }
            let fnValues = [Writer<[String], @Sendable (Int) -> Int>(inc, ["inc"]), Writer(dbl, ["dbl"])]
            let fns: @Sendable () -> PublisherTWriter<Never, [String], @Sendable (Int) -> Int> = {
                PublisherTWriter(fnValues.publisher.eraseToAnyPublisher())
            }

            #expect(collect(make().rawValue) == values)
            let escaped: Stack = make().mapPublisherT { $0.prefix(1).eraseToAnyPublisher() }
            #expect(collect(escaped.rawValue) == [Writer(1, ["a"])])
            #expect(collect(make().map(CoreFP.id).rawValue) == values)
            #expect(collect(make().map(inc).map(dbl).rawValue) == collect(make().map { dbl(inc($0)) }.rawValue))
            #expect(collect(Stack.apply(fns(), make()).rawValue) == collect(fns().flatMap { fn in make().map(fn) }.rawValue))
            #expect(collect(Stack.pure(3).flatMap(f).rawValue) == collect(f(3).rawValue))
            #expect(collect(make().flatMap(Stack.pure).rawValue) == values)
            #expect(collect(make().flatMap(f).flatMap(g).rawValue) == collect(make().flatMap(Stack.kleisli(f, g)).rawValue))
        }

        // MARK: - PublisherTStateful (applicative-only)

        @Test func publisherTStatefulLaws() {
            typealias Stack = PublisherTStateful<Never, Int, Int>
            let make: @Sendable () -> Stack = { [tick, Stateful<Int, Int>.pure(7)].publisher.eraseToAnyPublisher().publisherT }
            let observe: (Stack) -> [[Int]] = { collect($0.rawValue).map(runAt1) }
            let pureFn = PublisherTStateful<Never, Int, @Sendable (Int) -> Int>.pure

            #expect(observe(make()) == [[20, 2], [7, 1]])
            let escaped: Stack = make().mapPublisherT { $0.prefix(1).eraseToAnyPublisher() }
            #expect(observe(escaped) == [[20, 2]])
            #expect(observe(make().map(CoreFP.id)) == observe(make()))
            #expect(observe(make().map(inc).map(dbl)) == observe(make().map { dbl(inc($0)) }))
            // `apply` zips while `pure` is a single `Just`, so identity only holds for single-element streams.
            let single = Stack([tick].publisher.eraseToAnyPublisher())
            #expect(observe(Stack.apply(pureFn { $0 }, single)) == observe(single))
            #expect(observe(Stack.apply(pureFn(inc), Stack.pure(4))) == observe(Stack.pure(5)))
        }
    }
#endif
