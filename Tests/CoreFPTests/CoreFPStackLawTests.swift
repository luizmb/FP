// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
#endif
import CoreFP
import Testing

// Functor / applicative / monad laws on the struct API of the CoreFP stacks, plus one test of
// each stack's escape hatch (`mapXT`) and lifting property.

private enum LawError: Error, Equatable { case boom }

private let inc: @Sendable (Int) -> Int = { $0 + 1 }
private let dbl: @Sendable (Int) -> Int = { $0 * 2 }
private let identity: @Sendable (Int) -> Int = id

// MARK: - ArrayTOptional

@Suite struct ArrayTOptionalLawTests {
    private let m = ArrayTOptional<Int>([1, nil, 3])
    private let f: @Sendable (Int) -> ArrayTOptional<Int> = { ArrayTOptional([$0, nil]) }
    private let g: @Sendable (Int) -> ArrayTOptional<Int> = { ArrayTOptional([$0 * 10]) }

    @Test func functorLaws() {
        #expect(m.map(identity).rawValue == m.rawValue)
        #expect(m.map { dbl(inc($0)) }.rawValue == m.map(inc).map(dbl).rawValue)
    }

    @Test func applyIsAp() {
        let fns = ArrayTOptional<@Sendable (Int) -> Int>([inc, nil, dbl])
        #expect(ArrayTOptional.apply(fns, m).rawValue == fns.flatMap { fn in m.map(fn) }.rawValue)
    }

    @Test func monadLaws() {
        #expect(ArrayTOptional.pure(2).flatMap(f).rawValue == f(2).rawValue)
        #expect(m.flatMap(ArrayTOptional.pure).rawValue == m.rawValue)
        #expect(m.flatMap(f).flatMap(g).rawValue == m.flatMap { f($0).flatMap(g) }.rawValue)
    }

    @Test func escapeHatchAndLifting() {
        let nested: [Int?] = [1, nil]
        #expect(nested.arrayT.rawValue == nested)
        #expect(nested.arrayT.mapMaybeT { $0.compactMap(\.self).map(Optional.some) }.rawValue == [1])
    }
}

// MARK: - ArrayTResult

@Suite struct ArrayTResultLawTests {
    private let m = ArrayTResult<LawError, Int>([.success(1), .failure(.boom), .success(3)])
    private let f: @Sendable (Int) -> ArrayTResult<LawError, Int> = { ArrayTResult([.success($0), .failure(.boom)]) }
    private let g: @Sendable (Int) -> ArrayTResult<LawError, Int> = { ArrayTResult([.success($0 * 10)]) }

    @Test func functorLaws() {
        #expect(m.map(identity).rawValue == m.rawValue)
        #expect(m.map { dbl(inc($0)) }.rawValue == m.map(inc).map(dbl).rawValue)
    }

    @Test func applyIsAp() {
        let fns = ArrayTResult<LawError, @Sendable (Int) -> Int>([.success(inc), .failure(.boom), .success(dbl)])
        #expect(ArrayTResult.apply(fns, m).rawValue == fns.flatMap { fn in m.map(fn) }.rawValue)
    }

    @Test func monadLaws() {
        #expect(ArrayTResult.pure(2).flatMap(f).rawValue == f(2).rawValue)
        #expect(m.flatMap(ArrayTResult.pure).rawValue == m.rawValue)
        #expect(m.flatMap(f).flatMap(g).rawValue == m.flatMap { f($0).flatMap(g) }.rawValue)
    }

    @Test func escapeHatchAndLifting() {
        let nested: [Result<Int, LawError>] = [.success(1), .failure(.boom)]
        #expect(nested.arrayT.rawValue == nested)
        #expect(nested.arrayT.mapExceptT { Array($0.prefix(1)) }.rawValue == [.success(1)])
    }
}

// MARK: - OptionalTArray

// swiftlint:disable discouraged_optional_collection
@Suite struct OptionalTArrayLawTests {
    private let m = OptionalTArray<Int>([1, 2])
    private let f: @Sendable (Int) -> OptionalTArray<Int> = { OptionalTArray([$0, $0 + 1]) }
    private let g: @Sendable (Int) -> OptionalTArray<Int> = { OptionalTArray($0 > 2 ? nil : [$0 * 10]) }

    @Test func functorLaws() {
        #expect(m.map(identity).rawValue == m.rawValue)
        #expect(m.map { dbl(inc($0)) }.rawValue == m.map(inc).map(dbl).rawValue)
    }

    @Test func applyIsAp() {
        let fns = OptionalTArray<@Sendable (Int) -> Int>([inc, dbl])
        #expect(OptionalTArray.apply(fns, m).rawValue == fns.flatMap { fn in m.map(fn) }.rawValue)
    }

    @Test func monadLaws() {
        #expect(OptionalTArray.pure(2).flatMap(f).rawValue == f(2).rawValue)
        #expect(m.flatMap(OptionalTArray.pure).rawValue == m.rawValue)
        #expect(m.flatMap(f).flatMap(g).rawValue == m.flatMap { f($0).flatMap(g) }.rawValue)
    }

    @Test func escapeHatchAndLifting() {
        let nested: [Int]? = [1, 2]
        #expect(nested.optionalT.rawValue == nested)
        #expect(nested.optionalT.mapOptionalT { $0.map { $0.reversed() } }.rawValue == [2, 1])
    }
}

// swiftlint:enable discouraged_optional_collection

// MARK: - OptionalTResult

@Suite struct OptionalTResultLawTests {
    private let ms: [OptionalTResult<LawError, Int>] = [
        OptionalTResult(nil),
        OptionalTResult(.failure(.boom)),
        OptionalTResult(.success(2))
    ]
    private let f: @Sendable (Int) -> OptionalTResult<LawError, Int> = { OptionalTResult($0 > 1 ? .success($0 * 10) : nil) }
    private let g: @Sendable (Int) -> OptionalTResult<LawError, Int> = { OptionalTResult($0 > 50 ? .failure(.boom) : .success($0 + 1)) }

    @Test func functorLaws() {
        for m in ms {
            #expect(m.map(identity).rawValue == m.rawValue)
            #expect(m.map { dbl(inc($0)) }.rawValue == m.map(inc).map(dbl).rawValue)
        }
    }

    @Test func applyIsAp() {
        let fns = OptionalTResult<LawError, @Sendable (Int) -> Int>(.success(inc))
        for m in ms {
            #expect(OptionalTResult.apply(fns, m).rawValue == fns.flatMap { fn in m.map(fn) }.rawValue)
        }
    }

    @Test func monadLaws() {
        #expect(OptionalTResult.pure(2).flatMap(f).rawValue == f(2).rawValue)
        for m in ms {
            #expect(m.flatMap(OptionalTResult.pure).rawValue == m.rawValue)
            #expect(m.flatMap(f).flatMap(g).rawValue == m.flatMap { f($0).flatMap(g) }.rawValue)
        }
    }

    @Test func escapeHatchAndLifting() {
        let nested: Result<Int, LawError>? = .success(1)
        #expect(nested.optionalT.rawValue == nested)
        #expect(nested.optionalT.mapExceptT { $0.flatMap { try? $0.get() }.map { Result<String, LawError>.success("\($0)") } }
            .rawValue == .success("1"))
    }
}

// MARK: - AsyncStreamTOptional

@Suite struct AsyncStreamTOptionalLawTests {
    private let values: [Int?] = [1, nil, 3]
    private let f: @Sendable (Int) -> AsyncStreamTOptional<Int> = { streamOf([$0, nil]).asyncStreamT }
    private let g: @Sendable (Int) -> AsyncStreamTOptional<Int> = { streamOf([$0 * 10] as [Int?]).asyncStreamT }

    private func m() -> AsyncStreamTOptional<Int> { streamOf(values).asyncStreamT }

    @Test func functorLaws() async {
        let mappedIdentity = await collectAll(m().map(identity).rawValue)
        #expect(mappedIdentity == values)
        let composed = await collectAll(m().map { dbl(inc($0)) }.rawValue)
        let chained = await collectAll(m().map(inc).map(dbl).rawValue)
        #expect(chained == composed)
    }

    @Test func applyIsAp() async {
        let fns: [(@Sendable (Int) -> Int)?] = [inc, nil, dbl]
        let xs = values
        let applied = await collectAll(AsyncStreamTOptional.apply(streamOf(fns).asyncStreamT, m()).rawValue)
        let derived = await collectAll(streamOf(fns).asyncStreamT.flatMap { fn in streamOf(xs).asyncStreamT.map(fn) }.rawValue)
        #expect(applied == derived)
    }

    @Test func monadLaws() async {
        let leftIdentity = await collectAll(AsyncStreamTOptional.pure(2).flatMap(f).rawValue)
        let direct = await collectAll(f(2).rawValue)
        #expect(leftIdentity == direct)
        let rightIdentity = await collectAll(m().flatMap(AsyncStreamTOptional.pure).rawValue)
        #expect(rightIdentity == values)
        let lhs = await collectAll(m().flatMap(f).flatMap(g).rawValue)
        let rhs = await collectAll(m().flatMap { [f, g] x in f(x).flatMap(g) }.rawValue)
        #expect(lhs == rhs)
    }

    @Test func escapeHatchAndLifting() async {
        let lifted = await collectAll(m().rawValue)
        #expect(lifted == values)
        // The hatch hands over the whole stream; here it is replaced outright.
        let mapped = m().mapAsyncStreamT(const(streamOf(["a", nil])))
        let hatched = await collectAll(mapped.rawValue)
        #expect(hatched == ["a", nil])
    }
}

// MARK: - AsyncStreamTResult

@Suite struct AsyncStreamTResultLawTests {
    private let values: [Result<Int, LawError>] = [.success(1), .failure(.boom), .success(3)]
    private let f: @Sendable (Int) -> AsyncStreamTResult<LawError, Int> = { AsyncStreamTResult(streamOf([.success($0), .failure(.boom)])) }
    private let g: @Sendable (Int) -> AsyncStreamTResult<LawError, Int> = { AsyncStreamTResult(streamOf([.success($0 * 10)])) }

    private func m() -> AsyncStreamTResult<LawError, Int> { streamOf(values).asyncStreamT }

    @Test func functorLaws() async {
        let mappedIdentity = await collectAll(m().map(identity).rawValue)
        #expect(mappedIdentity == values)
        let composed = await collectAll(m().map { dbl(inc($0)) }.rawValue)
        let chained = await collectAll(m().map(inc).map(dbl).rawValue)
        #expect(chained == composed)
    }

    @Test func applyIsAp() async {
        let fns: [Result<@Sendable (Int) -> Int, LawError>] = [.success(inc), .failure(.boom)]
        let xs = values
        let applied = await collectAll(AsyncStreamTResult.apply(streamOf(fns).asyncStreamT, m()).rawValue)
        let derived = await collectAll(streamOf(fns).asyncStreamT.flatMap { fn in streamOf(xs).asyncStreamT.map(fn) }.rawValue)
        #expect(applied == derived)
    }

    @Test func monadLaws() async {
        let leftIdentity = await collectAll(AsyncStreamTResult.pure(2).flatMap(f).rawValue)
        let direct = await collectAll(f(2).rawValue)
        #expect(leftIdentity == direct)
        let rightIdentity = await collectAll(m().flatMap(AsyncStreamTResult.pure).rawValue)
        #expect(rightIdentity == values)
        let lhs = await collectAll(m().flatMap(f).flatMap(g).rawValue)
        let rhs = await collectAll(m().flatMap { [f, g] x in f(x).flatMap(g) }.rawValue)
        #expect(lhs == rhs)
    }

    @Test func escapeHatchAndLifting() async {
        let lifted = await collectAll(m().rawValue)
        #expect(lifted == values)
        // The hatch hands over the whole stream; here it is replaced outright.
        let mapped = m().mapAsyncStreamT(const(streamOf([Result<String, LawError>.success("a")])))
        let hatched = await collectAll(mapped.rawValue)
        #expect(hatched == [.success("a")])
    }
}

// MARK: - AsyncStreamTArray (applicative only)

@Suite struct AsyncStreamTArrayLawTests {
    private let values: [[Int]] = [[1, 2], [], [3]]

    private func m() -> AsyncStreamTArray<Int> { streamOf(values).asyncStreamT }

    @Test func functorLaws() async {
        let mappedIdentity = await collectAll(m().map(identity).rawValue)
        #expect(mappedIdentity == values)
        let composed = await collectAll(m().map { dbl(inc($0)) }.rawValue)
        let chained = await collectAll(m().map(inc).map(dbl).rawValue)
        #expect(chained == composed)
    }

    @Test func applicativeIdentityAndHomomorphism() async {
        // `apply` is AsyncStream's `ap` composed with Array's, so identity holds for any stream.
        let applied = await collectAll(AsyncStreamTArray.apply(AsyncStreamTArray.pure(identity), m()).rawValue)
        #expect(applied == values)
        let homomorphism = await collectAll(AsyncStreamTArray.apply(AsyncStreamTArray.pure(inc), AsyncStreamTArray.pure(4)).rawValue)
        let pureResult = await collectAll(AsyncStreamTArray.pure(inc(4)).rawValue)
        #expect(pureResult == homomorphism)
    }

    @Test func escapeHatchAndLifting() async {
        let lifted = await collectAll(m().rawValue)
        #expect(lifted == values)
        // The hatch hands over the whole stream; here it is replaced outright.
        let mapped = m().mapAsyncStreamT(const(streamOf([["a"]])))
        let hatched = await collectAll(mapped.rawValue)
        #expect(hatched == [["a"]])
    }
}

#if canImport(Combine)
    private func collect<A, E: Error>(_ publisher: AnyPublisher<A, E>) -> [A] {
        var results: [A] = []
        var cancellables = Set<AnyCancellable>()
        publisher
            .sink(receiveCompletion: { _ in }, receiveValue: { results.append($0) })
            .store(in: &cancellables)
        return results
    }

    // MARK: - PublisherTOptional

    @Suite struct PublisherTOptionalLawTests {
        private let values: [Int?] = [1, nil, 3]
        private let f: @Sendable (Int) -> PublisherTOptional<Never, Int> = { PublisherTOptional([$0, nil].publisher.eraseToAnyPublisher()) }
        private let g: @Sendable (Int) -> PublisherTOptional<Never, Int> = { PublisherTOptional(Just($0 * 10).eraseToAnyPublisher()) }

        private func m() -> PublisherTOptional<Never, Int> { values.publisher.eraseToAnyPublisher().publisherT }

        @Test func functorLaws() {
            #expect(collect(m().map(identity).rawValue) == values)
            #expect(collect(m().map { dbl(inc($0)) }.rawValue) == collect(m().map(inc).map(dbl).rawValue))
        }

        @Test func applyIsAp() {
            let fns: [(@Sendable (Int) -> Int)?] = [inc, nil, dbl]
            let fnsT = PublisherTOptional<Never, @Sendable (Int) -> Int>(fns.publisher.eraseToAnyPublisher())
            let xs = values
            let derived = fnsT.flatMap { fn in PublisherTOptional(xs.publisher.eraseToAnyPublisher()).map(fn) }
            #expect(collect(PublisherTOptional.apply(fnsT, m()).rawValue) == collect(derived.rawValue))
        }

        @Test func monadLaws() {
            #expect(collect(PublisherTOptional.pure(2).flatMap(f).rawValue) == collect(f(2).rawValue))
            #expect(collect(m().flatMap(PublisherTOptional.pure).rawValue) == values)
            let fn = f
            let gn = g
            let lhs = m().flatMap(fn).flatMap(gn)
            let rhs = m().flatMap { x in fn(x).flatMap(gn) }
            #expect(collect(lhs.rawValue) == collect(rhs.rawValue))
        }

        @Test func escapeHatchAndLifting() {
            #expect(collect(m().rawValue) == values)
            let mapped = m().mapPublisherT { $0.compactMap(\.self).map(Optional.some).eraseToAnyPublisher() }
            #expect(collect(mapped.rawValue) == [1, 3])
        }
    }

    // MARK: - PublisherTResult

    @Suite struct PublisherTResultLawTests {
        private let values: [Result<Int, LawError>] = [.success(1), .failure(.boom), .success(3)]
        private let f: @Sendable (Int) -> PublisherTResult<Never, LawError, Int> = {
            PublisherTResult([Result<Int, LawError>.success($0), .failure(.boom)].publisher.eraseToAnyPublisher())
        }

        private let g: @Sendable (Int) -> PublisherTResult<Never, LawError, Int> = {
            PublisherTResult(Just(Result<Int, LawError>.success($0 * 10)).eraseToAnyPublisher())
        }

        private func m() -> PublisherTResult<Never, LawError, Int> { values.publisher.eraseToAnyPublisher().publisherT }

        @Test func functorLaws() {
            #expect(collect(m().map(identity).rawValue) == values)
            #expect(collect(m().map { dbl(inc($0)) }.rawValue) == collect(m().map(inc).map(dbl).rawValue))
        }

        @Test func applyIsAp() {
            let fns: [Result<@Sendable (Int) -> Int, LawError>] = [.success(inc), .failure(.boom)]
            let fnsT = PublisherTResult<Never, LawError, @Sendable (Int) -> Int>(fns.publisher.eraseToAnyPublisher())
            let xs = values
            let derived = fnsT.flatMap { fn in PublisherTResult(xs.publisher.eraseToAnyPublisher()).map(fn) }
            #expect(collect(PublisherTResult.apply(fnsT, m()).rawValue) == collect(derived.rawValue))
        }

        @Test func monadLaws() {
            #expect(collect(PublisherTResult.pure(2).flatMap(f).rawValue) == collect(f(2).rawValue))
            #expect(collect(m().flatMap(PublisherTResult.pure).rawValue) == values)
            let fn = f
            let gn = g
            let lhs = m().flatMap(fn).flatMap(gn)
            let rhs = m().flatMap { x in fn(x).flatMap(gn) }
            #expect(collect(lhs.rawValue) == collect(rhs.rawValue))
        }

        @Test func escapeHatchAndLifting() {
            #expect(collect(m().rawValue) == values)
            let mapped = m().mapPublisherT { $0.filter { (try? $0.get()) != nil }.eraseToAnyPublisher() }
            #expect(collect(mapped.rawValue) == [.success(1), .success(3)])
        }
    }

    // MARK: - PublisherTArray (applicative only)

    @Suite struct PublisherTArrayLawTests {
        private let values: [[Int]] = [[1, 2], [], [3]]

        private func m() -> PublisherTArray<Never, Int> { values.publisher.eraseToAnyPublisher().publisherT }

        @Test func functorLaws() {
            #expect(collect(m().map(identity).rawValue) == values)
            #expect(collect(m().map { dbl(inc($0)) }.rawValue) == collect(m().map(inc).map(dbl).rawValue))
        }

        @Test func applicativeIdentityAndHomomorphism() {
            // `apply` is Publisher's `ap` (ordered concat) composed with Array's, so identity holds for any stream.
            let pureIdentity = PublisherTArray<Never, @Sendable (Int) -> Int>.pure(identity)
            #expect(collect(PublisherTArray.apply(pureIdentity, m()).rawValue) == values)
            let pureInc = PublisherTArray<Never, @Sendable (Int) -> Int>.pure(inc)
            let homomorphism = PublisherTArray.apply(pureInc, PublisherTArray<Never, Int>.pure(4))
            #expect(collect(homomorphism.rawValue) == collect(PublisherTArray<Never, Int>.pure(inc(4)).rawValue))
        }

        @Test func escapeHatchAndLifting() {
            #expect(collect(m().rawValue) == values)
            let mapped = m().mapPublisherT { $0.filter { !$0.isEmpty }.eraseToAnyPublisher() }
            #expect(collect(mapped.rawValue) == [[1, 2], [3]])
        }
    }
#endif
